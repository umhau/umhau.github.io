# Weird.

This is the source for my personal programming website.  There's a guide stashed on the site for using basic markdown [here](/markdown_guide.md). 

Note: if git thinks tons of files have changed, you probably opened the folder in a windows machine. Use the following command to tell git it's all right. 

```shell
git config --global core.autocrlf input
```

## how to build locally

Do this on ubuntu, unless you want to mess with updating Ruby past version 2.3. clone the source, then install dependencies, then start the site.

```
git clone https://github.com/umhau/umhau.github.io.git
cd umhau.github.io
bash install_dependencies.sh
bundle exec jekyll serve --host 0.0.0.0
```

The `--host 0.0.0.0` bit means that the site is accessible at that port and the machine's IP on the local network.

I don't think that's necessary for getting the site to run on github pages, though.  It is necessary, however, if the site is going to be hosted somewhere else.

## TODO

### portfolio

* create a section for finished projects: the sermon stream setup, the disk mounting tool, the beowulf cluster, the camera monitoring system. Call it the 'projects' section: the high-level projects that might be the culmination of many other posts on the site.

### more posts:

* walkthrough my custom OS installation setup.  
* walkthrough some of the "unfinished, finished" projects: e.g., the RPI secretary project (that one's significant because it contains a complete init system)
* minecraft setup scripts
* connections script - RDP, ssh, sshfs all wrapped up in a single easy script.
* powershell installation script (nothing fancy except it's my first real ps script)

### aesthetic

* the sidebar looks unbalanced...center it (10% width on each side)
* category page lists of posts should match the explore page lists

### utility

* full text search.  Will need a local copy of the site for testing. See also: https://github.com/christian-fei/Simple-Jekyll-Search/wiki.  I think this is part of the solution:

```
"content"  : "{{ page.content | strip_html | strip_newlines }}"
{{ content }}
```

* find a simple way to add more posts: there's lots of small annoyances now, but nothing big.
* add category for 'procedures' that I do on a regular basis - backing up computers, installing the deps for working with the blog, etc. 
* multi-word categories: https://www.azurepatterns.com/2020/03/11/jekyll-categories
* condense categories to only 2 or so? (e.g., procedures, experiments, & 'dev notes', to make space for larger variety of topics)
