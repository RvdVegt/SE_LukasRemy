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
});