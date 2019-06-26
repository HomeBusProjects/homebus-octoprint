# homebus-octoprint

This is a simple HomeBus data source which publishes printer status for Octoprint-controlled printers.

## Usage

On its first run, `homebus-octoprint` needs to know how to find the HomeBus provisioning server.

```
bundle exec homebus-aqi -b homebus-server-IP-or-domain-name -P homebus-server-port
```

The port will usually be 80 (its default value).

Once it's provisioned it stores its provisioning information in `.env.provisioning`.

`homebus-octoprint` also needs to know:

- URL for Octoprint
- API key for Octoprint


