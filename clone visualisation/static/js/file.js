$(document).ready(function() {
	if($("#linescroll").length > 0) {
		$('html, body').animate({
	        scrollTop: $('#linescroll').offset().top - $('#linescroll').height() - 132
	    }, 'slow');
	}
    
    jQuery.expr.filters.offscreen = function(e) {
        var rect = e.getBoundingClientRect();
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

function dupblockClick(classID, fileName, lineStart) {
		console.log("test: " + classID);
		$('*[data-class="' + classID + '"]').each(function() {
			$(this).addClass("active");
		});

		$('*[data-class!="' + classID + '"]').each(function() {
			$(this).removeClass("active");
		});

		$.ajax({
            url: "/fileclasses",
            type: "get",
            data: {activeclass: classID,
            	   filename: fileName,
            	   linestart: lineStart},
            success: function(response) {
                $('#srcdupheader').html(response);
            },
            error: function(err) {
                console.log("Could not request files.");
            }
        });
    }