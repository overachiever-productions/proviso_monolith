using System.Management.Automation;

namespace Proviso.Processing
{
    public class ConfigurationError
    {
        public bool IsRecompareError { get; private set; }
        public ErrorRecord Error { get; private set; }

        // vNEXT: remove the kludgey 'IsRecomparisonError' flag in the .ctor (and possibly as a property?)
        //      and use static constructors instead - i.e., 'factory' approach of 2x static 'creation' methods. 
        //          one for RecompareError and one for ConfigError... 
        public ConfigurationError(ErrorRecord error, bool isRecomparisonError)
        {
            this.Error = error;
            this.IsRecompareError = isRecomparisonError;
        }
    }
}
