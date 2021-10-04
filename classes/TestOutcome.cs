using System.Management.Automation;

namespace Proviso.Models
{
    public class TestOutcome
    {
        public object Expected { get; private set; }
        public object Actual { get; private set; }
        public bool Matched { get; private set; }
        public ErrorRecord Error { get; private set; }

        public TestOutcome(object expectedResult, object actualResult, bool matched, ErrorRecord error)
        {
            this.Expected = expectedResult;
            this.Actual = actualResult;
            this.Matched = matched;
            this.Error = error;
        }
    }
}