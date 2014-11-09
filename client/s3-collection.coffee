class S3Collection extends Meteor.Collection
  constructor: (name = 's3collection') ->
    super(name, connection: null)

    @logger = new Logger("S3Collection{#{name}}")
    @_progress = new ReactiveVar(0)

  getProgress: () ->
    @_progress.get()

  setProgress: (completion) ->
    @_progress.set(completion)

  uploadEveryNSeconds: (n) ->
    if @_uploadFrequency?
      throw new Error('repeat uploaded already enabled')

    @logger.info "Uploading collection evey #{n} seconds"

    @_uploadFrequency = n
    @_uploadEveryNSeconds()

  _uploadEveryNSeconds: ->
    frequency = @_uploadFrequency
    nextSynchronize = @_uploadEveryNSeconds.bind(@)
    download = @downloadFromS3.bind(@)
    upload = @uploadToS3.bind(@)
    logger = @logger

    upload (err) ->
      if err?
        logger.error(err)

      Meteor.setTimeout nextSynchronize, frequency * 1000

  uploadToS3: (callback) ->
    @setProgress(0)

    uploader = new S3ClientsideUploader()
    logger = @logger
    data = @find().fetch()

    progress = @setProgress.bind(@)

    Meteor.call 's3CollectionSyncPolicy', @_name, (err, policy) ->
      return callback(err) if err?

      progress(0.2)

      logger.info "Uploading to #{policy.awsBaseUrl}"

      finished = (xhr) ->
        if xhr.status != 204
          msg = "Received HTTP status #{xhr.status} from S3, expected 204"
          logger.error xhr
          callback(new Error(msg))
        else
          callback(null)

        Meteor.defer (-> progress(0))

      uploader.upload data, policy, finished, (e) ->
        if e.lengthComputable
          completed = 0.2 + (e.loaded / e.total) * 0.8
          progress(completed)

  downloadFromS3: (callback) ->
    Meteor.call 's3CollectionUrl', @_name, (err, url) =>
      return callback(err) if err?

      @logger.info "Downloading from #{url}"

      HTTP.get url, (err, res) =>
        return callback(err) if err?

        if res.statusCode != 200
          err = new Error(
            "Received status code #{res.statusCode} when fetching #{url}"
          )
          return callback(err, null)

        @_mergeFromS3(res.data)

        callback(null) if callback?

  replaceLocalStrategy: (local, remote) ->
    false

  addLocalStrategy: (remote) ->
    true

  _mergeFromS3: (data) ->
    count = data.length
    added = 0
    replaced = 0

    for s3Item in data
      id = s3Item._id
      localItem = @findOne(id)
      if localItem?
        if @replaceLocalStrategy(localItem, s3Item)
          @update(id, s3Item)
          replaced += 1
      else if @addLocalStrategy(s3Item)
        @insert s3Item
        added += 1

    msg = "Merged #{count} items. #{replaced} updated. #{added} inserted"
    @logger.info msg
