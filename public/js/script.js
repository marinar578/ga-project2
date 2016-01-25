$(document).ready(function(){


    // menus in nav
    var menu_items = $('#current-user');

    menu_items.hover(function(){
        $(this).children('ul.sub_main_navigation').show();
        $(this).children('a').addClass('hover');
        }, function(){
        $(this).children('ul.sub_main_navigation').hide();
        $(this).children('a').removeClass('hover');
    });


    // add category box
    var category = $('#category');

    category.click(function(){
        $(".cat").show();
    })

    // search by title
    $('body').on('keyup', function(event){
        if(event.which==13){       
            var userInput= $('#search').val();
            var userId = $('#'+userInput);
            var inputToReg = new RegExp(userInput, 'i');

            if (userInput.length > 0) {
                $('.article_titles').hide();
                // use the following line to show only articles whose tites match the search exactly
                // userId.show();

                //use this code to show articles whose titles match part of the search
                // for(i=0; i<$('.article_titles').length; i++){
                //    if (($('.article_titles')[i]["id"]).match(inputToReg)) {
                //      $('.article_titles:nth-child('+ (i+1) +')').show();
                //    };
                // };
                for(i=0; i<$('.article_titles').length; i++){
                   if ($('.article_titles td:nth-child(1)').text()).match(inputToReg)) {
                     $('.article_titles:nth-child('+ (i+1) +')').show();
                   };
                };
                
            };
            if (userInput.length == 0) {
                $('.article_titles').show();
            };
        };
    });

});
