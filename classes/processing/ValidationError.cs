using System.Management.Automation;
using Proviso.Enums;

namespace Proviso.Processing
{
    public class ValidationError
    {
        public ValidationErrorType ErrorType { get; private set; } 
        public ErrorRecord Error { get; private set; }

        public ValidationError(ValidationErrorType source, ErrorRecord error)
        {
            this.ErrorType = source;
            this.Error = error;
        }
    }
}