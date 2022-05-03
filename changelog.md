
# Change Log

## [0.7] - 2022-05-03
Major Overhaul of previous code.

### Added 
- Changelog.md
- Runbooks. (Collections of Surfaces to process as a single, cohesive, unit.)
- More 'intrinsics' (built-in $PVxxx objects/classes). 
- SQL Server version/patches (CUs and SPs) Surface. 

### Rewrote
- Configuration Management, mapping/extraction. MASSIVE overhaul of previous logic. 

### Fixed 
- Dynamic Facet creation - now more standardized/logical. 

### Known-Issues
- Still in Alpha status, needs better error handling. 
- Cluster config/setup not complete. 
- AG config/setup not complete. 
- Custom (SQL / Posh) Scripts not complete. 
- Restart is a mess. It works (except during ServerInitialization if/when joining a new domain - ScheduledTask won't start), but is kludgey - needs better orchestration, etc. 
- Data Collector Sets will NOT start if/when created (known bug) and won't correctly 'set' to auto-start (known bug).
- Number of formatting and other know (minor) bugs. 