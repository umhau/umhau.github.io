# set up new blog using minimal theme (built & customized locally)

npm install simple-jekyll-search
git clone https://github.com/umhau/umhau.github.io.git; cd umhau.github.io
sudo apt install ruby ruby-dev nodejs npm
sudo gem install jekyll bundler

sudo script/bootstrap # builds dependencies
bundle install # install gemfiles, etc

bundle exec jekyll serve # and you can access the site at http://localhost:4000/
