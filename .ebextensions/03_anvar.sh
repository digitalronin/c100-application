e are things that make sense for any Ruby application

# Install git in order to be able to bundle gems from git
packages:
  yum:
    git: []
    patch: []

commands:
  #01 && 02 needs for build native extension. See https://forums.aws.amazon.com/thread.jspa?messageID=550901&#550053
  01_bundlerfix_command:
    test: test ! -f /opt/elasticbeanstalk/containerfiles/.post-provisioning-complete
    command: gem install rubygems-update
    leader_only: false
  02_update_rubygems:
    test: test ! -f /opt/elasticbeanstalk/containerfiles/.post-provisioning-complete
    command: $(which update_rubygems)
    leader_only: false
  # Run rake with bundle exec to be sure you get the right version
  add_bundle_exec:
    test: test ! -f /opt/elasticbeanstalk/support/.post-provisioning-complete
    cwd: /opt/elasticbeanstalk/hooks/appdeploy/pre
    command: perl -pi -e 's/((?<!bundle exec )rake)/bundle exec $1/g' 11_asset_compilation.sh 12_db_migration.sh
  # Bundle with --deployment as recommended by bundler docs
  #   cf. http://gembundler.com/v1.2/rationale.html under Deploying Your Application
  add_deployment_flag:
    test: test ! -f /opt/elasticbeanstalk/support/.post-provisioning-complete
    cwd: /opt/elasticbeanstalk/hooks/appdeploy/pre
    command: perl -pi -e 's/(bundle install(?! --deployment))/$1 --deployment/' 10_bundle_install.sh
  # Vendor gems to a persistent directory for speedy subsequent bundling
  make_vendor_bundle_dir:
    test: test ! -f /opt/elasticbeanstalk/support/.post-provisioning-complete
    command: mkdir -p /var/app/support/vendor_bundle
  # Store the location of vendored gems in a handy env var
  set_vendor_bundle_var:
    test: test ! -f /opt/elasticbeanstalk/support/.post-provisioning-complete
    cwd: /opt/elasticbeanstalk/support
    command: sed -i '12iexport EB_CONFIG_APP_VENDOR_BUNDLE=$EB_CONFIG_APP_SUPPORT/vendor_bundle' envvars
  # The --deployment flag tells bundler to install gems to vendor/bundle/, so
  # symlink that to the persistent directory
  symlink_vendor_bundle:
    test: test ! -f /opt/elasticbeanstalk/support/.post-provisioning-complete
    cwd: /opt/elasticbeanstalk/hooks/appdeploy/pre
    command: sed -i 's/\(^cd $EB_CONFIG_APP_ONDECK\)/\1\nln -s $EB_CONFIG_APP_VENDOR_BUNDLE .\/vendor\/bundle/' 10_bundle_install.sh
  # Don't run the above commands again on this instance
  #   cf. http://stackoverflow.com/a/16846429/283398
  z_write_post_provisioning_complete_file:
    cwd: /opt/elasticbeanstalk/support
    command: touch .post-provisioning-complete
