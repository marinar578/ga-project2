$(document).ready(function(){

  /* Menus */

  var menu_items = $('#current-user');

 menu_items.hover(function(){
      $(this).children('ul.sub_main_navigation').show();
      $(this).children('a').addClass('hover');
 }, function(){
      $(this).children('ul.sub_main_navigation').hide();
      $(this).children('a').removeClass('hover');
 });

});
