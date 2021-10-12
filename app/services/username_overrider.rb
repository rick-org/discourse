# frozen_string_literal: true

class UsernameOverrider
  def self.override(user, new_username)
    if user.username_lower == User.normalize_username(new_username)
      user.username = new_username # there may be a change of case
      true
    elsif user.username != UserNameSuggester.fix_username(new_username)
      suggested_username = UserNameSuggester.suggest(new_username)
      UsernameChanger.change(user, suggested_username, user)
      true
    else
      false
    end
  end
end
