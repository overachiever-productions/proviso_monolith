using System;

namespace Proviso.Enums
{
    [Flags]
    public enum FacetProcessingState : int
    {
        Initialized = 0, 
        AssertsStarted = 1, 
        AssertsEnded = 2, 
        ValidationsStarted = 4, 
        ValidationsEnded = 8,
        RebaseStarted = 16, 
        RebaseEnded = 32, 
        ConfigurationsStarted = 64, 
        ConfigurationsEnded = 128, 
        AssertsFailed = 256, 
        ValidationsFailed = 512,
        RebaseFailed = 1024,
        ConfigurationsFailed = 2048,
        RecompareFailed = 4096,
        Failed = 8192  // generic exception.
    }
}