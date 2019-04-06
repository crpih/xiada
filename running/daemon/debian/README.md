# TAGGER instalation as system daemon

To install XIADA as a system daemon we must follow next steps:

1) Create xiada user and adds it to staff group.
2) Install Ruby version (>= 2.1) with .rbenv inside this user.

	git clone https://github.com/rbenv/rbenv.git ~/.rbenv
	echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
	~/.rbenv/bin/rbenv init >> ~/.bashrc
	source ~/.bashrc
	curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash
	mkdir -p "$(rbenv root)"/plugins
	git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
	rbenv install 2.4.5
	rbenv global 2.4.5

3) Copy needed gems for the tagger:

	gem install bundler sqlite3 dbi

4) Run:

	sudo make install
	sudo make daemon_install

5) Launch the service

  sudo service xiada start

In the case that the service does not start, error messages are logged to /var/log/daemon.log

To uninstall XIADA as a system daemon:

	sudo make uninstall
	sudo make daemon_uninstall
