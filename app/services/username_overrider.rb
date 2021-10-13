# frozen_string_literal: true

class UsernameOverrider
  def self.override(user, new_username)
    if user.username_lower == User.normalize_username(new_username)
      UsernameChanger.change(user, new_username, user)
      true
    elsif user.username != UserNameSuggester.fix_username(new_username)
      user.username = UserNameSuggester.suggest(new_username)
      true
    else
      false
    end
  end
end

=begin
test cases:
  - override if the new name isn't the same
  - do not override if the new name is the same

  - override if the new name has another case
  - override if the new name is unnormalized username with another case

  - do not override if the name after fixing is the same
  - override with username suggestions
=end
