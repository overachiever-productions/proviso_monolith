
# Change Log

## [0.8.0] - 2023-04-19 
Started on this 'branch' around September 15 of 2022 - by moving gobs of logic/etc. into Premise and PSI. 
Fast forward a few months and ... Proviso.Core is/was the new approach. 
AND, ultimately, I opted to 'revert' back to the branch from September 15, 2022- as a way of KEEPING a buggy/non-perfect but FUNCTIONAL version of Proviso (old) running in lab. 
i.e., v0.8.0 doesn't really 'exist'. 

## [0.7.9] - 2022-11-29
Ridiculous number of changes - too many to document.

### Known Issues 
- Still in an Alpha Stage. 

### Main Changes
- Full Rewrite of CONFIG functionality (2x  different times) - more object oriented. 
- Standardization of Iterators for Surface/Facet processing. 
- Extraction of core 'helper' logic out into Premise - new project/library. This'll allow better re-architecture of what Proviso is (effectively just a provisioning/validation tool/framework - vs provisioning/validation tool + huge library of 'helper' funcs). It'll also allow eventual integration (dependency upon) DbaTools - so that Proviso isn't bogged-down with implementation details and, again/instead: focuses more or IaC/compliance and evaluation. 

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