Handlebars.registerHelper "key_value", (context, options) ->
    result = []
    _.each context, (value, key, list) ->
        result.push
            key: key
            value: value
    result
