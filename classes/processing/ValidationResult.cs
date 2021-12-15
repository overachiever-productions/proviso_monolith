using System.Collections.Generic;
using System.Management.Automation;
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
        public ScriptBlock Expectation => this.ParentDefinition.Expectation;
        public ScriptBlock Configure => this.ParentDefinition.Configure;
        public ScriptBlock Test => this.ParentDefinition.Test;
        public bool Failed { get; private set; }  // not the same as matched vs not-matched... but failed (i.e., an exception somewhere).

        public List<ValidationError> ValidationErrors { get; private set; }

        public ValidationResult(Definition parent, object expectedResult, object actualResult, bool matched)
        {
            this.ParentDefinition = parent;
            this.Expected = expectedResult;
            this.Actual = actualResult;
            this.Matched = matched;

            this.Failed = false;
            this.ValidationErrors = new List<ValidationError>();
        }

        public void AddValidationError(ValidationError added)
        {
            this.Failed = true;
            this.ValidationErrors.Add(added);
        }

        public string GetFacetName()
        {
            return this.ParentDefinition.Parent.Name;
        }
    }
}
