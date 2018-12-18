$(document).ready(function() {
    $('.sortoption').click(function() {
        $(this).siblings('.active').removeClass('active');
        $(this).addClass("active");
    });

    $('#dupsort').click(function() {
        var reverse;
        var order = this.getAttribute("data-order");

        if (order == "-1" || order == "0") {
            this.setAttribute("data-order", "1");
            $('#dupsortorder').html("&#9650");
            reverse = false;
        }
        else if (order == "1") {
            this.setAttribute("data-order", "-1");
            $('#dupsortorder').html("&#9660;");
            reverse = true;
        }

        $(this).siblings("[data-order]").attr("data-order", "0");
        $(this).siblings("[data-order]").find("span").html("-");

        $.ajax({
            url: "/dupsort",
            type: "get",
            data: {reverse: reverse},
            success: function(response) {
                $('#scrollfiles').html(response);
            },
            error: function(err) {
                console.log("Could not request files.");
                console.log(err);
            }
        });
    });

    $('#dupfilesort').click(function() {
        var reverse;
        var order = this.getAttribute("data-order");

        if (order == "-1" || order == "0") {
            this.setAttribute("data-order", "1");
            $('#dupfilesortorder').html("&#9650");
            reverse = false;
        }
        else if (order == "1") {
            this.setAttribute("data-order", "-1");
            $('#dupfilesortorder').html("&#9660");
            reverse = true;
        }

        $(this).siblings("[data-order]").attr("data-order", "0");
        $(this).siblings("[data-order]").find("span").html("-");

        $.ajax({
            url: "/dupfilesort",
            type: "get",
            data: {reverse: reverse},
            success: function(response) {
                $('#scrollfiles').html(response);
            },
            error: function(err) {
                console.log("Could not request files.");
            }
        });
    });

    jQuery.expr.filters.offscreen = function(e) {
        var rect = e.getBoudningClientRect();
        return (
                (rect.x + rect.width) < 0
                    || (rect.y + rect.height) < 0
                    || (rect.x > window.innerWidth || rect.y > window.innerHeight)
            );
    }

    $("div.srcblock").mousemove(function(e) {
        var tt = $(e.currentTarget).children(".srctooltip")[0];

        var x = (e.clientX + 10) + "px";
        var y = (e.clientY + 10) + "px";
        var screenWidth = $(window).width();
        var screenHeight = $(window).height();
        var scrollHeight = $(window).scrollTop();


        if (e.clientX + 10 + $(tt).width() >= screenWidth) {
            $(tt).css("left", (screenWidth - $(tt).width()) + "px");
        } else {
            $(tt).css("left", x);
        }

        if (e.clientY + 10 + $(tt).height() >= screenHeight) {
            $(tt).css("top", (screenHeight - $(tt).height()) + "px");
        } else {
            $(tt).css("top", y);
        }
    });

    // When the user scrolls the page, execute myFunction
    window.onscroll = function() {stickyHeader()};
    // Get the header
    var header = document.getElementById("srcdupheader");
    // Get the offset position of the navbar
    var sticky = header.offsetTop;
    // Add the sticky class to the header when you reach its scroll position. Remove "sticky" when you leave the scroll position
    function stickyHeader() {
      if (window.pageYOffset > sticky) {
        header.classList.add("stickyheader");
      } else {
        header.classList.remove("stickyheader");
      }
    } 
});