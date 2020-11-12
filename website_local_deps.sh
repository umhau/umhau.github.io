# set up new blog using minimal theme (built & customized locally)

# dependencies
sudo apt install ruby ruby-dev nodejs npm
sudo gem install jekyll bundler
npm install simple-jekyll-search

sudo script/bootstrap # builds dependencies
bundle install # install gemfiles, etc

bundle exec jekyll serve # and you can access the site at http://localhost:4000/
