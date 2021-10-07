# frozen_string_literal: true

# name: discourse-presence
# about: Show which users are replying to a topic, or editing a post
# version: 2.0
# authors: André Pereira, David Taylor, tgxworld
# url: https://github.com/discourse/discourse/tree/main/plugins/discourse-presence
# transpile_js: true

enabled_site_setting :presence_enabled
hide_plugin if self.respond_to?(:hide_plugin)

register_asset 'stylesheets/presence.scss'

after_initialize do

  register_presence_channel_prefix("discourse-presence") do |channel_name|
    if topic_id = channel_name[/\/discourse-presence\/reply\/(\d+)/, 1]
      topic = Topic.find(topic_id)
      config = PresenceChannel::Config.new

      if topic.private_message?
        config.allowed_user_ids = topic.allowed_users.pluck(:id)
        config.allowed_group_ids = topic.allowed_groups.pluck(:group_id) + [::Group::AUTO_GROUPS[:staff]]
      elsif secure_group_ids = topic.secure_group_ids
        config.allowed_group_ids = secure_group_ids
      else
        config.public = true
      end

      config
    elsif topic_id = channel_name[/\/discourse-presence\/whisper\/(\d+)/, 1]
      Topic.find(topic_id) # Just ensure it exists
      PresenceChannel::Config.new(allowed_group_ids: [::Group::AUTO_GROUPS[:staff]])
    elsif post_id = channel_name[/\/discourse-presence\/edit\/(\d+)/, 1]
      post = Post.find(post_id)
      topic = post.topic
      next nil if topic.nil?

      config = PresenceChannel::Config.new

      config.allowed_user_ids = [ post.user_id ]
      config.allowed_group_ids = [ ::Group::AUTO_GROUPS[:staff] ]

      if post.locked? || post.whisper?
        # no additional groups/users allowed
      elsif topic.private_message? && post.wiki
        # Ignore trust level and just publish to all allowed groups since
        # trying to figure out which users in the allowed groups have
        # the necessary trust levels can lead to a large array of user ids
        # if the groups are big.
        config.allowed_user_ids += topic.allowed_users.pluck(:id)
        config.allowed_group_ids += topic.allowed_groups.pluck(:id)
      elsif post.wiki
        config.allowed_group_ids << Group::AUTO_GROUPS[:"trust_level_#{SiteSetting.min_trust_to_edit_wiki_post}"]
      elsif !topic.private_message? && SiteSetting.trusted_users_can_edit_others?
        config.allowed_group_ids << Group::AUTO_GROUPS[:trust_level_4]
      end
      config
    end
  rescue ActiveRecord::NotFound
    nil
  end
end
