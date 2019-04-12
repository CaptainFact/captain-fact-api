# Change Log

## [v1.0.2](https://github.com/CaptainFact/captain-fact-api/tree/v1.0.2) (2019-04-01)
[Full Changelog](https://github.com/CaptainFact/captain-fact-api/compare/v1.0.1...v1.0.2)

**Fixed bugs:**

- GenServer terminating \(MatchError\): no match of right hand side value: {:error, :cannot\_create\_table} [\#135](https://github.com/CaptainFact/captain-fact-api/issues/135)
- GenServer terminating \(MatchError\): no match of right hand side value: {:error, :cannot\_create\_table} [\#134](https://github.com/CaptainFact/captain-fact-api/issues/134)

**Merged pull requests:**

- Improve CI tests and release configs [\#141](https://github.com/CaptainFact/captain-fact-api/pull/141) ([Betree](https://github.com/Betree))
- Edit speaker enhancements [\#138](https://github.com/CaptainFact/captain-fact-api/pull/138) ([Betree](https://github.com/Betree))
- fix\(RuntimeConfig\): Basic auth password [\#137](https://github.com/CaptainFact/captain-fact-api/pull/137) ([Betree](https://github.com/Betree))
- chore\(deps\): bump timex from 3.3.0 to 3.5.0 [\#113](https://github.com/CaptainFact/captain-fact-api/pull/113) ([dependabot[bot]](https://github.com/apps/dependabot))

## [v1.0.1](https://github.com/CaptainFact/captain-fact-api/tree/v1.0.1) (2019-03-25)
[Full Changelog](https://github.com/CaptainFact/captain-fact-api/compare/v1.0.0...v1.0.1)

**Fixed bugs:**

- DBConnection.ConnectionError: connection not available because of disconnection [\#132](https://github.com/CaptainFact/captain-fact-api/issues/132)
- GenServer terminating \(DBConnection.ConnectionError\): connection not available because of disconnection [\#131](https://github.com/CaptainFact/captain-fact-api/issues/131)
- DBConnection.ConnectionError: connection not available because of disconnection [\#130](https://github.com/CaptainFact/captain-fact-api/issues/130)
- GenServer terminating \(ArgumentError\): argument error [\#127](https://github.com/CaptainFact/captain-fact-api/issues/127)

**Merged pull requests:**

- Release 1.0.1 [\#133](https://github.com/CaptainFact/captain-fact-api/pull/133) ([Betree](https://github.com/Betree))
- fix\(SubscriptionsMatcher\): Don't return canceled subscriptions [\#129](https://github.com/CaptainFact/captain-fact-api/pull/129) ([Betree](https://github.com/Betree))
- Release 1.0.0 [\#126](https://github.com/CaptainFact/captain-fact-api/pull/126) ([Betree](https://github.com/Betree))

## [v1.0.0](https://github.com/CaptainFact/captain-fact-api/tree/v1.0.0) (2019-03-19)
[Full Changelog](https://github.com/CaptainFact/captain-fact-api/compare/v0.9.3...v1.0.0)

**Fixed bugs:**

- GenServer terminating: exited in: GenServer.call\(CF.RestApi.Presence, {:list, "video\_debate:4P7J"}, 5000\)
    \*\* \(EXIT\) no process: the process is not alive or there's no process currently associated with the given name, possibly because its application i [\#110](https://github.com/CaptainFact/captain-fact-api/issues/110)

**Merged pull requests:**

- Notifications [\#60](https://github.com/CaptainFact/captain-fact-api/pull/60) ([Betree](https://github.com/Betree))

## [v0.9.3](https://github.com/CaptainFact/captain-fact-api/tree/v0.9.3) (2019-01-05)
[Full Changelog](https://github.com/CaptainFact/captain-fact-api/compare/v0.9.2...v0.9.3)

**Fixed bugs:**

- CF.Accounts.UserPermissions.PermissionsError: unauthorized [\#92](https://github.com/CaptainFact/captain-fact-api/issues/92)

**Closed issues:**

- Add API key to users [\#50](https://github.com/CaptainFact/captain-fact-api/issues/50)
- Ability to export verification results [\#10](https://github.com/CaptainFact/captain-fact-api/issues/10)
- User account deletion : soft delete [\#8](https://github.com/CaptainFact/captain-fact-api/issues/8)
- Add a cleanup job to remove expired password reset requests [\#7](https://github.com/CaptainFact/captain-fact-api/issues/7)
- \[New achievements\] Hit machine, fact's tamer, you made a point [\#5](https://github.com/CaptainFact/captain-fact-api/issues/5)

**Merged pull requests:**

- Release 0.9.3 [\#109](https://github.com/CaptainFact/captain-fact-api/pull/109) ([Betree](https://github.com/Betree))
- Videos: add unlisted and get all added by user [\#107](https://github.com/CaptainFact/captain-fact-api/pull/107) ([Betree](https://github.com/Betree))
- chore\(ActivityLog\): Show user banned actions [\#105](https://github.com/CaptainFact/captain-fact-api/pull/105) ([Betree](https://github.com/Betree))
- chore\(deps\): bump floki from 0.20.3 to 0.20.4 [\#104](https://github.com/CaptainFact/captain-fact-api/pull/104) ([dependabot[bot]](https://github.com/apps/dependabot))
- chore\(deps-dev\): bump mix\_test\_watch from 0.8.0 to 0.9.0 [\#103](https://github.com/CaptainFact/captain-fact-api/pull/103) ([dependabot[bot]](https://github.com/apps/dependabot))
- chore\(deps-dev\): bump ex\_machina from 2.2.0 to 2.2.2 [\#102](https://github.com/CaptainFact/captain-fact-api/pull/102) ([dependabot[bot]](https://github.com/apps/dependabot))
- chore\(deps-dev\): bump bypass from 0.8.1 to 0.9.0 [\#99](https://github.com/CaptainFact/captain-fact-api/pull/99) ([dependabot[bot]](https://github.com/apps/dependabot))
- feat\(Limitations\): Check actions on a 15 minutes period instead of 24h [\#98](https://github.com/CaptainFact/captain-fact-api/pull/98) ([Betree](https://github.com/Betree))
- chore\(deps\): bump distillery from 2.0.11 to 2.0.12 [\#95](https://github.com/CaptainFact/captain-fact-api/pull/95) ([dependabot[bot]](https://github.com/apps/dependabot))
- chore\(deps\): bump absinthe\_plug from 1.4.5 to 1.4.6 [\#93](https://github.com/CaptainFact/captain-fact-api/pull/93) ([dependabot[bot]](https://github.com/apps/dependabot))
- chore\(deps\): bump basic\_auth from 2.2.2 to 2.2.4 [\#91](https://github.com/CaptainFact/captain-fact-api/pull/91) ([dependabot[bot]](https://github.com/apps/dependabot))
- chore\(deps\): bump oauth2 from 0.9.2 to 0.9.4 [\#89](https://github.com/CaptainFact/captain-fact-api/pull/89) ([dependabot[bot]](https://github.com/apps/dependabot))
- chore\(deps\): bump comeonin from 4.1.1 to 4.1.2 [\#88](https://github.com/CaptainFact/captain-fact-api/pull/88) ([dependabot[bot]](https://github.com/apps/dependabot))
- chore\(deps\): bump ecto from 2.2.10 to 2.2.11 [\#87](https://github.com/CaptainFact/captain-fact-api/pull/87) ([dependabot[bot]](https://github.com/apps/dependabot))
- chore\(deps\): bump guardian from 1.1.0 to 1.1.1 [\#85](https://github.com/CaptainFact/captain-fact-api/pull/85) ([dependabot[bot]](https://github.com/apps/dependabot))
- chore\(deps-dev\): bump credo from 0.10.0 to 1.0.0 [\#83](https://github.com/CaptainFact/captain-fact-api/pull/83) ([dependabot[bot]](https://github.com/apps/dependabot))
- chore\(deps-dev\): bump excoveralls from 0.9.1 to 0.10.3 [\#82](https://github.com/CaptainFact/captain-fact-api/pull/82) ([dependabot[bot]](https://github.com/apps/dependabot))
- chore\(deps\): bump mime from 1.3.0 to 1.3.1 [\#80](https://github.com/CaptainFact/captain-fact-api/pull/80) ([dependabot[bot]](https://github.com/apps/dependabot))

## [v0.9.2](https://github.com/CaptainFact/captain-fact-api/tree/v0.9.2) (2018-12-29)
[Full Changelog](https://github.com/CaptainFact/captain-fact-api/compare/v0.9.1...v0.9.2)

**Merged pull requests:**

- Release 0.9.2 [\#78](https://github.com/CaptainFact/captain-fact-api/pull/78) ([Betree](https://github.com/Betree))
- Fix youtube fetch strategy [\#77](https://github.com/CaptainFact/captain-fact-api/pull/77) ([Betree](https://github.com/Betree))
- fix\(GraphQL\): Add missing cf dependency [\#76](https://github.com/CaptainFact/captain-fact-api/pull/76) ([Betree](https://github.com/Betree))
- chore\(Limitations\): Softer limitations for update user [\#74](https://github.com/CaptainFact/captain-fact-api/pull/74) ([Betree](https://github.com/Betree))
- chore\(WS\): Return a proper unauthorized error when calling authenticated [\#73](https://github.com/CaptainFact/captain-fact-api/pull/73) ([Betree](https://github.com/Betree))
- dev\(Emails\): Make the procedure to dev emails clearer [\#72](https://github.com/CaptainFact/captain-fact-api/pull/72) ([Betree](https://github.com/Betree))
- chore\(FrontendRouter\): Use unique comments URLs [\#71](https://github.com/CaptainFact/captain-fact-api/pull/71) ([Betree](https://github.com/Betree))

## [v0.9.1](https://github.com/CaptainFact/captain-fact-api/tree/v0.9.1) (2018-12-20)
[Full Changelog](https://github.com/CaptainFact/captain-fact-api/compare/v0.9.0...v0.9.1)

**Fixed bugs:**

- Phoenix.Router.NoRouteError: no route found for GET /socket/longpoll \(CF.RestApi.Router\) [\#67](https://github.com/CaptainFact/captain-fact-api/issues/67)
- Phoenix.Router.NoRouteError: no route found for GET /socket/longpoll \(CF.RestApi.Router\) [\#56](https://github.com/CaptainFact/captain-fact-api/issues/56)
- OAuth2.Error: Server responded with status: 400

Headers:

www-authenticate: OAuth "Facebook Platform" "invalid\_code" "This authorization code has been used."
content-type: application/json
facebook-api-version: v2.8
x-fb-rev: 4560566
access-control-allow [\#54](https://github.com/CaptainFact/captain-fact-api/issues/54)
- Jobs tests frequently fail [\#41](https://github.com/CaptainFact/captain-fact-api/issues/41)

**Closed issues:**

- \[Atom Feed\] Flags [\#34](https://github.com/CaptainFact/captain-fact-api/issues/34)
- Passwordless authentication [\#12](https://github.com/CaptainFact/captain-fact-api/issues/12)

**Merged pull requests:**

- Release 0.9.1 [\#69](https://github.com/CaptainFact/captain-fact-api/pull/69) ([Betree](https://github.com/Betree))
- Allow longpoll connections [\#68](https://github.com/CaptainFact/captain-fact-api/pull/68) ([Betree](https://github.com/Betree))
- Fix crash with facebook signup when name length is \> 20 [\#66](https://github.com/CaptainFact/captain-fact-api/pull/66) ([Betree](https://github.com/Betree))
- Fix error when trying to enter an empty speaker title [\#65](https://github.com/CaptainFact/captain-fact-api/pull/65) ([Betree](https://github.com/Betree))
- chore\(TravisCI\): Check code format before running tests [\#64](https://github.com/CaptainFact/captain-fact-api/pull/64) ([Betree](https://github.com/Betree))
- Videos can now handle multiple providers [\#63](https://github.com/CaptainFact/captain-fact-api/pull/63) ([Betree](https://github.com/Betree))
- Delete docker dev scripts [\#62](https://github.com/CaptainFact/captain-fact-api/pull/62) ([Betree](https://github.com/Betree))
- Fix timestamps in videos list [\#61](https://github.com/CaptainFact/captain-fact-api/pull/61) ([Betree](https://github.com/Betree))
- chore\(CI\): Move release script out of travis config [\#59](https://github.com/CaptainFact/captain-fact-api/pull/59) ([Betree](https://github.com/Betree))
- feat: Add Atom Feed for flags [\#57](https://github.com/CaptainFact/captain-fact-api/pull/57) ([btrd](https://github.com/btrd))
- Disable jobs scheduler in tests [\#53](https://github.com/CaptainFact/captain-fact-api/pull/53) ([Betree](https://github.com/Betree))
- Release 0.9 [\#52](https://github.com/CaptainFact/captain-fact-api/pull/52) ([Betree](https://github.com/Betree))

## [v0.9.0](https://github.com/CaptainFact/captain-fact-api/tree/v0.9.0) (2018-11-23)
[Full Changelog](https://github.com/CaptainFact/captain-fact-api/compare/v0.8.17...v0.9.0)

**Fixed bugs:**

- Sources length is limited to 255 characters [\#42](https://github.com/CaptainFact/captain-fact-api/issues/42)

**Closed issues:**

- throw: "Hello World" [\#48](https://github.com/CaptainFact/captain-fact-api/issues/48)
- RuntimeError: Hello World [\#47](https://github.com/CaptainFact/captain-fact-api/issues/47)

**Merged pull requests:**

- Replace "Anonymous user" label by "Deleted account" [\#51](https://github.com/CaptainFact/captain-fact-api/pull/51) ([Betree](https://github.com/Betree))
- Add errors reporting with Rollbar [\#49](https://github.com/CaptainFact/captain-fact-api/pull/49) ([Betree](https://github.com/Betree))
- Fix ability to confuse new fetcher mime\_type with URL params [\#46](https://github.com/CaptainFact/captain-fact-api/pull/46) ([Betree](https://github.com/Betree))
- Store source URL MIME type [\#45](https://github.com/CaptainFact/captain-fact-api/pull/45) ([Betree](https://github.com/Betree))
- Increase sources max URL length to 2048 [\#44](https://github.com/CaptainFact/captain-fact-api/pull/44) ([Betree](https://github.com/Betree))
- Umbrella app refactor - Part II ☂🌩🐋 [\#38](https://github.com/CaptainFact/captain-fact-api/pull/38) ([Betree](https://github.com/Betree))
- Replace CaptainFactJobs.Vote by realtime messages [\#37](https://github.com/CaptainFact/captain-fact-api/pull/37) ([Betree](https://github.com/Betree))
- Use ecto\_enum for UserAction type and entity [\#36](https://github.com/CaptainFact/captain-fact-api/pull/36) ([Betree](https://github.com/Betree))

## [v0.8.17](https://github.com/CaptainFact/captain-fact-api/tree/v0.8.17) (2018-11-01)
[Full Changelog](https://github.com/CaptainFact/captain-fact-api/compare/v0.8.14...v0.8.17)

**Implemented enhancements:**

- Ability to login using email or username alike [\#9](https://github.com/CaptainFact/captain-fact-api/issues/9)

**Fixed bugs:**

- Fix a bug preventing from shift all statements [\#28](https://github.com/CaptainFact/captain-fact-api/pull/28) ([Betree](https://github.com/Betree))

**Closed issues:**

- Ability to import captions from YouTube [\#11](https://github.com/CaptainFact/captain-fact-api/issues/11)

**Merged pull requests:**

- Release 0.8.17 [\#35](https://github.com/CaptainFact/captain-fact-api/pull/35) ([Betree](https://github.com/Betree))
- Add the ability to disable CORS in config, set  them to disabled by default in dev [\#30](https://github.com/CaptainFact/captain-fact-api/pull/30) ([Betree](https://github.com/Betree))
- Use raw video title as entry title in videos atom feed [\#29](https://github.com/CaptainFact/captain-fact-api/pull/29) ([Betree](https://github.com/Betree))
- Add ability to login using email or username alike [\#27](https://github.com/CaptainFact/captain-fact-api/pull/27) ([adri](https://github.com/adri))
- Fix typo [\#26](https://github.com/CaptainFact/captain-fact-api/pull/26) ([ruudk](https://github.com/ruudk))
- Add ability to import captions from YouTube [\#25](https://github.com/CaptainFact/captain-fact-api/pull/25) ([adri](https://github.com/adri))
- Unified docker release [\#24](https://github.com/CaptainFact/captain-fact-api/pull/24) ([Betree](https://github.com/Betree))
- Return a proper 404 error when speaker doesn't exist [\#23](https://github.com/CaptainFact/captain-fact-api/pull/23) ([Betree](https://github.com/Betree))
- Paginated videos list [\#22](https://github.com/CaptainFact/captain-fact-api/pull/22) ([Betree](https://github.com/Betree))
- Videos atom feed [\#20](https://github.com/CaptainFact/captain-fact-api/pull/20) ([Betree](https://github.com/Betree))
- Release 0.8.15 [\#19](https://github.com/CaptainFact/captain-fact-api/pull/19) ([Betree](https://github.com/Betree))
- Use markdown format for statement feed [\#18](https://github.com/CaptainFact/captain-fact-api/pull/18) ([Betree](https://github.com/Betree))
- Use new relationship model for UserAction [\#17](https://github.com/CaptainFact/captain-fact-api/pull/17) ([Betree](https://github.com/Betree))
- Create CODE\_OF\_CONDUCT.md [\#16](https://github.com/CaptainFact/captain-fact-api/pull/16) ([Betree](https://github.com/Betree))
- Generate hashId and store it in DB [\#15](https://github.com/CaptainFact/captain-fact-api/pull/15) ([Betree](https://github.com/Betree))
- Improve comments Atom feed rendering [\#14](https://github.com/CaptainFact/captain-fact-api/pull/14) ([Betree](https://github.com/Betree))
- Store Q letter in wikidata\_item\_id + Disable speakers validation feature [\#3](https://github.com/CaptainFact/captain-fact-api/pull/3) ([Betree](https://github.com/Betree))
- \[CI\] Travis config [\#2](https://github.com/CaptainFact/captain-fact-api/pull/2) ([Betree](https://github.com/Betree))

## [v0.8.14](https://github.com/CaptainFact/captain-fact-api/tree/v0.8.14) (2018-08-18)
[Full Changelog](https://github.com/CaptainFact/captain-fact-api/compare/v0.8.13...v0.8.14)

## [v0.8.13](https://github.com/CaptainFact/captain-fact-api/tree/v0.8.13) (2018-08-05)
[Full Changelog](https://github.com/CaptainFact/captain-fact-api/compare/v0.8.12...v0.8.13)

## [v0.8.12](https://github.com/CaptainFact/captain-fact-api/tree/v0.8.12) (2018-07-19)
[Full Changelog](https://github.com/CaptainFact/captain-fact-api/compare/v0.8.10...v0.8.12)

## [v0.8.10](https://github.com/CaptainFact/captain-fact-api/tree/v0.8.10) (2018-05-18)
[Full Changelog](https://github.com/CaptainFact/captain-fact-api/compare/v0.8.7...v0.8.10)

## [v0.8.7](https://github.com/CaptainFact/captain-fact-api/tree/v0.8.7) (2018-04-13)
[Full Changelog](https://github.com/CaptainFact/captain-fact-api/compare/v0.8.6...v0.8.7)

## [v0.8.6](https://github.com/CaptainFact/captain-fact-api/tree/v0.8.6) (2018-03-25)
[Full Changelog](https://github.com/CaptainFact/captain-fact-api/compare/v0.8.3...v0.8.6)

## [v0.8.3](https://github.com/CaptainFact/captain-fact-api/tree/v0.8.3) (2018-03-06)
[Full Changelog](https://github.com/CaptainFact/captain-fact-api/compare/v0.8.0...v0.8.3)

## [v0.8.0](https://github.com/CaptainFact/captain-fact-api/tree/v0.8.0) (2018-01-25)
[Full Changelog](https://github.com/CaptainFact/captain-fact-api/compare/v0.2.0...v0.8.0)

## [v0.2.0](https://github.com/CaptainFact/captain-fact-api/tree/v0.2.0) (2017-03-29)


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*