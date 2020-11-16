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

* the sidebar looks unbalanced...center it (10% width on each side)
* category page lists of posts should match the explore page lists

### utility

* full text search.  Will need a local copy of the site for testing. I think this is part of the solution:

```
"content"  : "{{ page.content | strip_html | strip_newlines }}"
```

* find a simple way to add more posts: there's lots of small annoyances now, but nothing big.
* add category for 'procedures' that I do on a regular basis - backing up computers, installing the deps for working with the blog, etc. 
* multi-word categories: https://www.azurepatterns.com/2020/03/11/jekyll-categories
* condense categories to only 2 or so? (e.g., walkthroughs & 'dev notes', to make space for larger variety of topics)
