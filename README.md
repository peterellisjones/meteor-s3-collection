meteor-s3-collection
====================

Clientside-only Minimongo collection that persists to S3 in the background.

It expected two methods on the server-side: `s3CollectionSyncPolicy` which should return an S3 policy document created by [s3-policy-generator](https://github.com/peterellisjones/meteor-s3-policy-generator/), and `s3CollectionUrl` which should return the URL to the S3 file that the collection should persist to:

```coffee-script
# server.coffee

Meteor.methods
  s3CollectionSyncPolicy: (name) ->
    check(name, String)

    unless @userId?
      throw new Meteor.Error('must be logged in')

    path = "cards/#{@userId}.json"

    options =
      acl: 'public-read'
      maxBytes: 1024 * 1024 * 5
      contentType: 'application/json'

    policyGenerator.generate(path, options)

  s3CollectionUrl: (name) ->
    check(name, String)

    unless @userId?
      throw new Meteor.Error('must be logged in')

    "#{Meteor.settings.AWS_S3_BASE_URL}/cards/#{@userId}.json"

```

Example usage on the client:

```coffee-script
# client.coffee

Cards = new S3Collection('cards')

# After logging in, 
# download existing user cards from S3
# then backup every minute
Tracker.autorun ->
  if Meteor.user()?
    Cards.downloadFromS3 (err) ->
      console.err if err?
      # note this can only be called once
      Cards.uploadEveryNSeconds(60) 
```

For fancy merging strategies when updating local data, replace `replaceLocalStrategy`, and `addLocalStrategy` on the collection. eg:

```coffee-script
# replaceLocalStrategy should return a boolean
# true => replace the local object with the one from S3
Cards.replaceLocalStrategy = (local, remote) ->
  remote.modified > local.modified

# addLocalStrategy should return a boolean
# true => add the S3 object to the local collection
Cards.addLocalStrategy = (remote) ->
  true
```



