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

    var srcTooltips = document.querySelectorAll(".srctooltip");
    console.log(srcTooltips);
    window.onmousemove = function(e) {
        var x = (e.clientX + 10) + "px";
        var y = (e.clientY + 10) + "px";
        for (var i = 0; i < srcTooltips.length; i++) {
            var screenWidth = $(window).width();
            var screenHeight = $(window).height();
            var scrollHeight = $(window).scrollTop();


            if (e.clientX + 10 + $(srcTooltips[i]).width() >= screenWidth) {
                srcTooltips[i].style.left = (screenWidth - $(srcTooltips[i]).width()) + "px";
            } else {
                srcTooltips[i].style.left = x;
            }

            if (e.clientY + 10 + $(srcTooltips[i]).height() >= screenHeight) {
                srcTooltips[i].style.top = (screenHeight - $(srcTooltips[i]).height()) + "px";
            } else {
                srcTooltips[i].style.top = y;
            }
        }
    };
});