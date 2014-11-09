Package.describe({
  name: 'peterellisjones:s3-collection',
  summary: 'Allows you to create client-side Minimongo collections that are regularly saved as JSON on S3',
  version: '1.0.0',
  git: 'https://github.com/peterellisjones/meteor-s3-collection.git'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0');
  api.use('coffeescript');
  api.use('http');
  api.use('peterellisjones:logger@1.0.0');
  api.use('peterellisjones:s3-clientside-uploader@1.0.0');
  api.imply('peterellisjones:s3-policy-generator@1.0.0');
  api.addFiles('client/s3-collection.coffee');

  api.export('S3Collection');
});
