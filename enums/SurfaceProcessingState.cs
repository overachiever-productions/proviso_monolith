using System;

namespace Proviso.Enums
{
    [Flags]
    public enum SurfaceProcessingState : int
    {
        Initialized = 0, 
        AssertsStarted = 1, 
        AssertsSucceeded = 2, 
        ValidationsStarted = 4, 
        ValidationsSucceeded = 8,
        RebaseStarted = 16, 
        RebaseSucceeded = 32, 
        ConfigurationsStarted = 64, 
        ConfigurationsSucceeded = 128, 

        AssertsFailed = 256, 
        ValidationsFailed = 512,
        RebaseFailed = 1024,
        ConfigurationsFailed = 2048,
        RecompareFailed = 4096,
        
        Succeeded = 8192,

        Failed = 16384  // generic exception.
    }
}