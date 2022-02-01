using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using Proviso.Enums;
using Proviso.Models;

namespace Proviso.Processing
{
    public class ValidationResult
    {
        public Definition ParentDefinition { get; private set; }

        public string Description => this.ParentDefinition.Description;
        public object Expected { get; private set; }
        public object Actual { get; private set; }
        public bool Matched { get; private set; }
        public ScriptBlock Expectation => this.ParentDefinition.Expect;
        public ScriptBlock Configure => this.ParentDefinition.Configure;
        public ScriptBlock Test => this.ParentDefinition.Test;
        public bool Failed { get; private set; }  // not the same as matched vs not-matched... but failed (i.e., an exception somewhere).
        public Guid ProcessingId { get; private set; }

        public List<ValidationError> ValidationErrors { get; private set; }

        public ValidationResult(Definition parent, Guid processingId)
        {
            this.ParentDefinition = parent;
            this.ProcessingId = processingId;

            this.Failed = false;
            this.ValidationErrors = new List<ValidationError>();
        }

        public void AddExpectedResult(object expectedResult)
        {
            this.Expected = expectedResult;
        }

        public void AddComparisonResults(object actualResult, bool matched)
        {
            this.Actual = actualResult;
            this.Matched = matched;
        }

        public void AddValidationError(ValidationError added)
        {
            this.Failed = true;
            this.ValidationErrors.Add(added);
        }

        public string GetSurfaceName()
        {
            return this.ParentDefinition.Parent.Name;
        }

        public string GetValidationName()
        {
            return $"{this.ParentDefinition.Description}";
        }

        public string GetActualSummary()
        {
            // OUTCOME OPTIONS:
            //  a. failure/exception. 
            //  b. actual value... 

            if (this.Failed)
            {
                if (this.ValidationErrors.Count == 1)
                {
                    return "Exception: " + this.ValidationErrors[0].Error.Exception.Message;
                }
                else
                {
                    var exceptions = this.ValidationErrors.Where(x => x.ErrorType == ValidationErrorType.Actual);
                    if (exceptions.Count() == 1)
                    {
                        return "Exception collecting Actual: " + exceptions.First().Error.Exception.Message;
                    }
                    else
                        return "Multiple Exceptions evaluating Actual Block.";
                }
            }

            string output = Formatter.Instance.ToEmptyableString(this.Actual);

            return output;
        }
    }
}
