$(document).ready(function() {
    $('.sortoption').click(function() {
        $(this).siblings('.active').removeClass('active');
        $(this).addClass("active");
    });
});

function sortClones(e, url) {
    var reverse;
    var order = e.getAttribute("data-order");
    var icon = $("span", e).html();
    var neworder = "";

    if (order == "-1" || order == "0") {
        neworder = "1";
        icon = "&#9650";
        reverse = false;
    }
    else if (order == "1") {
        neworder = "-1";
        icon = "&#9660";
        reverse = true;
    }

    $.ajax({
        url: url,
        type: "get",
        data: {reverse: reverse},
        success: function(response) {
            $('#scrollfiles').html(response);
            $("span", e).html(icon);
            e.setAttribute("data-order", neworder);
            $(e).siblings("[data-order]").attr("data-order", "0");
            $(e).siblings("[data-order]").find("span").html("-");
            $(".sortoption.active").removeClass("active")
            $(e).addClass("active");
        },
        error: function(err) {
            console.log("Could not request files.");
            console.log(err);
        }
    });
}

function showOption(e, option1, option2) {
    console.log("123");
    // Replacing the scroll canvas with files.
    $.ajax({
        url: option1,
        type: "get",
        success: function(response) {
            showOption2(e, response, option2);
        },
        error: function(err) {
            console.log("Could not request files.");
        }
    });
}

function showOption2(e, res, option) {
    $.ajax({
        url: option,
        type: "get",
        success: function(response) {
            $("#header").html(response);
            $("#scrollfiles").html(res);
            $(".headerbutton.active").removeClass("active");
            $(e).addClass("active");
        },
        error: function(err) {
            console.log("Could not request files.");
        }
    });
}

function showPlots(e, option) {
    $.ajax({
        url: option,
        type: "get",
        success: function(response) {
            $("#header").html("");
            $("#scrollfiles").html(response);
            $(".headerbutton.active").removeClass("active");
            $(e).addClass("active");
        },
        error: function(err) {
            console.log("Could not request files.");
        }
    });
}
