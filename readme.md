# Weird.

This is the source for my personal programming website.  There's a guide stashed on the site for using basic markdown [here](/markdown_guide.md). 

## how to build locally

Do this on ubuntu, unless you want to mess with updating Ruby past version 2.3. clone the source, then install dependencies, then start the site.

```
git clone https://github.com/umhau/umhau.github.io.git
cd umhau.github.io
bash install_dependencies.sh
bundle exec jekyll serve
```

I don't think that's necessary for getting the site to run on github pages, though.  It is necessary, however, if the site is going to be hosted somewhere else.

## TODO

### aesthetic

* the sidebar needs to accommodate being too short. create a media entry in the css file for limited height. (solution: hide categories list? display:__?)
* removing the tag cloud scripts sped up the page regeneration from 4 sec to .2 sec. don't bring it back.
* the sidebar looks unbalanced...center it (10% width on each side)
* on each category page, make all pages in the category do infinite scroll under an `<hr>` line and the current list.
* category page lists of posts should match the explore page lists

### utility

* find a simple way to add more posts.
* add category for 'procedures' that I do on a regular basis - backing up computers, installing the deps for working with the blog, etc.  