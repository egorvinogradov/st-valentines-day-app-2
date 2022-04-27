People = new Meteor.Collection "people"

#People.allow
#    insert: ->
#        true
#    update: ->
#        true


#Meteor.users.allow
#    remove: ->
#        true


App =

    selectors:
        person: ".people__person"
        searchInput: ".people__search-input"
        loveButton: ".people__love-button"
        unloveButton: ".people__unlove-button"
        saveButton: ".account__save"
        firstNameInput: ".account__first-name-input"
        lastNameInput: ".account__last-name-input"
        photoInput: ".account__photo-input"
        facebookInput: ".account__facebook-input"
        accountModal: "#account"

    MAX_LOVED_COUNT: 5

    nameSearchQuery: ""
    peopleListUpdateCounter: 0

    initialize: (collection) ->
        console.log "Initialized app", collection
        @collection = collection
        @initializeTemplates()
        @attachEvents()

    attachEvents: ->
        peopleEvents = {}
        peopleEvents["click #{@selectors.loveButton}"] = $.proxy @onLoveButtonClick, @
        peopleEvents["click #{@selectors.unloveButton}"] = $.proxy @onUnloveButtonClick, @
        peopleEvents["keyup #{@selectors.searchInput}"] = $.proxy @onSearchInputKeyup, @

        headerEvents = {}
        headerEvents["click #{@selectors.saveButton}"] = $.proxy @onSaveButtonClick, @

        Template.people.events peopleEvents
        Template.header.events headerEvents

    initializeTemplates: ->
        Template.header.currentPerson = $.proxy @getTemplateCurrentPerson, @
        Template.peopleList.lastUpdate = $.proxy @getTemplateLastUpdate, @
        Template.peopleList.peopleList = $.proxy @getTemplatePeopleList, @
        Template.notifications.notifications = $.proxy @getTemplateNotifications, @
        Template.notifications.currentPerson = $.proxy @getTemplateCurrentPerson, @

    getPerson: (userId) ->
        @collection.findOne userId: userId

    getCurrentPerson: ->
        @getPerson Meteor.userId()

    getPeopleWhoLovePerson: (username) ->
        currentPerson = @collection.findOne username: username
        people = []
        @collection.find().forEach (person) ->
            if currentPerson.username isnt person.username
                if currentPerson.username in person.loved
                    people.push(person)
        people

    getUsernameByEventObject: (e) ->
        $(e.currentTarget)
            .parents(@selectors.person)
            .data("username")

    getLovedByCount: (username) ->
        @getPeopleWhoLovePerson(username).length #TODO: add +1 later

    getTemplateLastUpdate: ->
        Session.get "lastUpdate"

    getTemplatePeopleSearch: ->
        query: @nameSearchQuery

    getTemplatePeopleList: ->

        currentPerson = @getCurrentPerson()
        currentPersonTemplateData = null
        people = []

        if @nameSearchQuery
            searchQueryWords = @nameSearchQuery.split(/\s+/)

        @collection.find({}, sort: firstName: 1).forEach (person) =>

            templateData = {}
            if currentPerson

                templateData =
                    isLoved: person.username in currentPerson.loved
                    loggedIn: true
                    lovedBy: @getLovedByCount person.username

                if currentPerson.userId is person.userId
                    templateData.isCurrentUser = true
                    currentPersonTemplateData = _.extend(templateData, person)
                else
                    people.push _.extend(templateData, person)

            else
                templateData =
                    loggedIn: false
                    lovedBy: @getLovedByCount person.username
                people.push _.extend(templateData, person)

        if @nameSearchQuery
            people = people.filter (person) =>
                name = person.firstName + " " + person.lastName
                _.find name.split(/\s+/), (nameWord) =>
                    _.find searchQueryWords, (searchQueryWord) =>
                        nameWord.toLowerCase().indexOf(searchQueryWord.toLowerCase()) is 0

        people.unshift currentPersonTemplateData
        people

    getTemplateCurrentPerson: ->
        currentPerson = @getCurrentPerson()
        if currentPerson
            lovedBy = @getLovedByCount currentPerson.username
            _.extend lovedBy: lovedBy, currentPerson

    getTemplateNotifications: ->
        currentPerson = @getCurrentPerson()
        if currentPerson
            if currentPerson.username.toLowerCase() in ["egorvinogradov.ru", "elizabeth76"] # TODO: remove
                peopleWhoLoveCurrentPerson = @getPeopleWhoLovePerson currentPerson.username
                peopleIdsWhoLoveCurrentPerson = _.pluck(peopleWhoLoveCurrentPerson, "username")
                intersectionIds = _.intersection peopleIdsWhoLoveCurrentPerson, currentPerson.loved
                _.map intersectionIds, (username) =>
                    @collection.findOne username: username

    onLoveButtonClick: (e) ->

        currentPerson = @getCurrentPerson()
        username = @getUsernameByEventObject(e)

        if username isnt currentPerson.username
            loved = currentPerson.loved
            unless loved.length >= @MAX_LOVED_COUNT
                loved.push(username)
                query = _id: currentPerson._id
                @collection.update query, $set:
                    loved: loved
                console.log("Loved", username)

    onUnloveButtonClick: (e) ->
        currentPerson = @getCurrentPerson()
        username = @getUsernameByEventObject(e)
        if username isnt currentPerson.username
            loved = currentPerson.loved
            loved = _.without(loved, username)
            query = _id: currentPerson._id
            @collection.update query, $set:
                loved: loved
            console.log("Unloved", username)

    onSaveButtonClick: (e) ->
        e.preventDefault()
        e.stopPropagation()
        values =
            firstName: $.trim $(@selectors.firstNameInput).val()
            lastName: $.trim $(@selectors.lastNameInput).val()
            photo: $.trim $(@selectors.photoInput).val()
            facebook: $.trim $(@selectors.facebookInput).val()
        query = _id: @getCurrentPerson()._id
        $(@selectors.accountModal).modal "hide"

        setTimeout =>
            @collection.update query, $set: values
        , 500

    onSearchInputKeyup: (e) ->
        @nameSearchQuery = $.trim $(e.currentTarget).val()
        Session.set "lastUpdate", new Date()

    _generatePeople: (userList) ->
       userList.forEach (user) ->
           People.insert
               firstName: user[1]
               lastName: user[0]
               email: user[2]
               username: user[2].split("@")[0]
               about: ""
               loved: []
               photo: ""
               userId: ""
               facebook: ""
               activated: false



if Meteor.isClient
    App.initialize(People)



if Meteor.isServer
    Accounts.onCreateUser (options, user) ->
        currentPerson = People.findOne(email: options.email)
        if currentPerson
            console.log("Activated user", options.email, user._id, currentPerson.name)
            query = _id: currentPerson._id
            People.update query, $set:
                activated: true
                userId: user._id
        else
            console.log("Can't find user with email", options.email)
            user.emails[0].address = "Invalid email"
        user
