# Security scanning

Every tagged release is uploaded to [VirusTotal](https://www.virustotal.com/)
by CI **before** the GitHub Release is published, so a build that looks like
malware never reaches anyone. The results are recorded here.

| Release | Detections | Report | SHA-256 of the APK |
|---|---|---|---|
| [`v1.8.1`](https://github.com/zaifears/locreminder/releases/tag/v1.8.1) | 0 / 67 | [report](https://www.virustotal.com/gui/file/7c8ef162f17ebd3e7f3cf1a9619017965cfcffa0b09a597ec6a54f97cee6d981) | `7c8ef162f17ebd3e7f3cf1a9619017965cfcffa0b09a597ec6a54f97cee6d981` |
| [`v1.8.0`](https://github.com/zaifears/locreminder/releases/tag/v1.8.0) | 0 / 68 | [report](https://www.virustotal.com/gui/file/a263dc8b4f82f593409f011413cca8dae919fb7646c9ca40cd9697c2c649b336) | `a263dc8b4f82f593409f011413cca8dae919fb7646c9ca40cd9697c2c649b336` |
| [`v1.7.1`](https://github.com/zaifears/locreminder/releases/tag/v1.7.1) | 0 / 68 | [report](https://www.virustotal.com/gui/file/cb1e254ae3216e25f914873d5c33fae15ea3b10c14e78cb6de37a3f4ca797764) | `cb1e254ae3216e25f914873d5c33fae15ea3b10c14e78cb6de37a3f4ca797764` |
| [`v1.7.0`](https://github.com/zaifears/locreminder/releases/tag/v1.7.0) | 0 / 66 | [report](https://www.virustotal.com/gui/file/7469d9e76e2a816e9c6856b0949009aa36ee05d60993db76fb325c2bfe5161ff) | `7469d9e76e2a816e9c6856b0949009aa36ee05d60993db76fb325c2bfe5161ff` |
| [`v1.6.16`](https://github.com/zaifears/locreminder/releases/tag/v1.6.16) | 0 / 63 | [report](https://www.virustotal.com/gui/file/ca7226bda8910ee626fc40ea175676f11c734fbc7a509a40141c2a2764184b6d) | `ca7226bda8910ee626fc40ea175676f11c734fbc7a509a40141c2a2764184b6d` |
| [`v1.6.15`](https://github.com/zaifears/locreminder/releases/tag/v1.6.15) | 0 / 67 | [report](https://www.virustotal.com/gui/file/2a463f178e36f876584e8c31ce2a7efcf2a625a51181366d6700140a793ff970) | `2a463f178e36f876584e8c31ce2a7efcf2a625a51181366d6700140a793ff970` |
| [`v1.6.14`](https://github.com/zaifears/locreminder/releases/tag/v1.6.14) | 0 / 67 | [report](https://www.virustotal.com/gui/file/64cac3c76ea3ccab1078397eb53603e75a886ea8b20ba1aa191371626853bf35) | `64cac3c76ea3ccab1078397eb53603e75a886ea8b20ba1aa191371626853bf35` |
| [`v1.6.12`](https://github.com/zaifears/locreminder/releases/tag/v1.6.12) | 0 / 67 | [report](https://www.virustotal.com/gui/file/776a23c5f87b8c1e4ea1670496f8d5c8ef5a1f85bf98b10ad442610a159e4f78) | `776a23c5f87b8c1e4ea1670496f8d5c8ef5a1f85bf98b10ad442610a159e4f78` |
| [`v1.6.11`](https://github.com/zaifears/locreminder/releases/tag/v1.6.11) | 0 / 67 | [report](https://www.virustotal.com/gui/file/363678bb4b1ee097c1080477c8054d6f0f0f94620deab27abb6c9920d3d98523) | `363678bb4b1ee097c1080477c8054d6f0f0f94620deab27abb6c9920d3d98523` |
| [`v1.6.10`](https://github.com/zaifears/locreminder/releases/tag/v1.6.10) | 0 / 51 | [report](https://www.virustotal.com/gui/file/b868152d29b82e0e3491afc456241ce14c650b08384be5fd98d827b3ceea0647) | `b868152d29b82e0e3491afc456241ce14c650b08384be5fd98d827b3ceea0647` |
| [`v1.6.9`](https://github.com/zaifears/locreminder/releases/tag/v1.6.9) | 0 / 58 | [report](https://www.virustotal.com/gui/file/a450c2c6bdbf1640c489b1f09c70e92834c9f989da9060ec55ec2a8fef7bd605) | `a450c2c6bdbf1640c489b1f09c70e92834c9f989da9060ec55ec2a8fef7bd605` |
| [`v1.6.8`](https://github.com/zaifears/locreminder/releases/tag/v1.6.8) | 0 / 67 | [report](https://www.virustotal.com/gui/file/387497b76b02492701f6c22018ab61392224dfd948d9053c2d8524358b40d0fd) | `387497b76b02492701f6c22018ab61392224dfd948d9053c2d8524358b40d0fd` |
| [`v1.6.7`](https://github.com/zaifears/locreminder/releases/tag/v1.6.7) | 0 / 67 | [report](https://www.virustotal.com/gui/file/e288b08997bf4e80fe0f8d998404705e65d58efb1e888da9cf471c3e865818e1) | `e288b08997bf4e80fe0f8d998404705e65d58efb1e888da9cf471c3e865818e1` |

## Checking a download yourself

The table records the SHA-256 of each published APK. That matters as much as
the scan result: a clean report proves something about *a* file, and the hash
is what proves it was *this* one. To confirm the APK you downloaded is the
same file that was scanned:

```bash
Get-FileHash app-release.apk -Algorithm SHA256
```

```bash
sha256sum app-release.apk
```

Compare the result with the row above, then open the linked report.

## What this does and does not tell you

A clean VirusTotal result means roughly seventy antivirus engines recognised
nothing malicious in the package. That is worth having, and it would catch a
tampered artifact or a compromised dependency pulled in at build time.

It is not proof the app is safe, and no scan can be. Antivirus engines detect
things they have seen before; novel code passes. The stronger guarantees here
come from elsewhere: the source is public and the build is reproducible from
it, LocReminder has no analytics or backend to send anything to, and F-Droid
builds its own copy from source rather than trusting a binary at all.

Occasional detections are also normal for Android packages that request
background location and run foreground services — the behaviour a location
alarm needs is, in outline, the behaviour a tracker needs. A small number of
weaker engines flag that pattern generically. Releases are blocked
automatically only when the count is high enough to mean something.
