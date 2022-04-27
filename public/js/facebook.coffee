# Looking for people's photos by emails
# using Gravatar, Facebook and Google+ APIs


getPhotoByEmail = (email, callback) ->

    getGooglePhoto = (gCallback) ->
        $.ajax
            url: "http://plus.google.com/complete/search"
            dataType: "jsonp"
            timeout: 5000
            data:
                client: "es-people-picker"
                q: email
            success: (googleData) ->
                if googleData?[1]?[0]?[3]?.b
                    gCallback(googleData[1][0][3].b)
                else
                    gCallback("")
            error: ->
                gCallback("")

    $.ajax
        url: "http://gravatar.com/#{md5 email}.json"
        dataType: "jsonp"
        timeout: 5000
        success: (data) ->

            if data?.entry?[0]
                gravatarProfile = data.entry[0]
                gravatarPhoto = gravatarProfile.photos?[0]?.value
                if gravatarPhoto
                    gravatarPhoto = gravatarPhoto += "?s=200"

                if gravatarProfile.accounts?.length
                    facebook = _.find gravatarProfile.accounts, (account) =>
                        account.domain is "facebook.com"


                    if facebook.url
                        if /profile\.php/.test(facebook.url)
                            facebookId = facebook.url.split("profile.php?id=")[1]
                        else
                            facebookUsername = facebook.url.split(".com/")[1]
                        facebookPhoto = "http://graph.facebook.com/#{facebookId or facebookUsername}/picture?type=large"

                        callback(facebookPhoto)

                    else
                        callback(gravatarPhoto)
            else
                getGooglePhoto(callback)

        error: ->
            getGooglePhoto(callback)
