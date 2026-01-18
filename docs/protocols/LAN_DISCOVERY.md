> [!NOTE]
> DRAFT

# LAN Discovery

Doing things

Broadcast port: 4898

| Name              | Type     | Description                                                              |
|-------------------|----------|--------------------------------------------------------------------------|
| Version           | int32_t  | Version of protocol this application supports                            |
| Owner             | string   | Nickname of application's active user                                    |
| Hostname          | string   | Name of device                                                           |
| UUID              | string   | Unique identifier for this application                                   |
| Application       | string   | Name of application                                                      |
| Features          | array    | Array of strings naming features the application supports                |
| Service Port      | uint16_t | Dynamically assigned TCP port that interested parties should connect too |

> [!NOTE]
> Max packet size for UDP broadcast may need to be limited to 512 bytes

```json
{
  "version": 0,
  "owner": "cyberarm",
  "hostname": "PC-1692",
  "uuid": "019bcf1e-a22e-7fe0-a3db-3a9d37bfc6fa",
  "application": "W3D Hub Linux Launcher",
  "features": [
    "launcher_remote:3",
    "package_share:1"
  ],
  "service_port": 56802
}
```
