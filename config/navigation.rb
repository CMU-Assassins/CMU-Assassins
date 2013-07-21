SimpleNavigation::Configuration.run do |navigation|
  logged_in_check = lambda {!user.nil?}

  navigation.items do |primary|
    primary.dom_class = 'nav'
    primary.selected_class = 'active'
    primary.item :signup, 'Sign Up', url('/signup'),
                 :unless => logged_in_check
    primary.item :dashboard, 'Dashboard', url('/dashboard'),
                 :if => logged_in_check
    primary.item :leaderboard, 'Leaderboard', url('/leaderboard'),
                 :if => lambda {game_started?}
    primary.item :rules, 'Rules', url('/rules')
    primary.item :contact, 'Contact Us', url('/contact')
    primary.item :admin, 'Admin', url('/admin/dashboard'),
                 :if => lambda {admin?}
  end
end

# vim:set ts=2 sw=2 et:
