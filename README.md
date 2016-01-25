# PROJECT 2: Wiki

![wecreate site](public/css/images/wecreate.png "wecreate site")

# wecreate
is a sharing platform for creative writing projects. Use wecreate to collaboratively write and edit poetry and prose; work together to update your creative project as a group. 


## features
1. Create articles or edit existing articles
1. Articles can be written in markdown and rendered with markdown formatting
1. Search for article by title or browse through categories
1. Browse through articles by a specific author
1. Add to categories list and assign multiple categories to each new entry
1. View information about an article's updates, including who updated it and when
1. Authentication and security using BCrypt
1. Your gravatar is automatically added when you sign up!
1. Edit your account information, if necessary



## wireframe and tables
- ERD:
![database tables](https://trello-attachments.s3.amazonaws.com/56a597618d216e71ec9b50c3/600x800/ffca684bb77ba196b422abad5f182bc6/IMG_0962.JPG.jpg "db tables")
- wireframe:
![wireframe](https://trello-attachments.s3.amazonaws.com/56a5973f57cedfd3feaf1c1b/600x800/7c30e483eb9a836eaaf2edd4fa84197b/IMG_0964.JPG.jpg "wireframe")


#### additional features to come!
- allow users to choose groups for a creative writing project; limit user permissions for editing and deleting an article
- implement track changes
- allow users access to API with JSON endpoints
- add "order-by" option in articles view
- ability to create new category on the spot when adding an article
- search-by date/author, etc. functionality


#### To view the site locally:
Download this github repo and use your terminal to navigate to the directory where it's stored. Type "rackup" in your terminal to launch the site locally. Make sure you have psql installed. Create a database called "wiki" and initiate it with the db/seeds.rb file.

