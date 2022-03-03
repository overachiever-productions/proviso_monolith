using System;
using System.Management.Automation;
using Moq;
using NUnit.Framework;
using Proviso.Processing;

namespace Proviso.Models.Tests.Models
{
    [TestFixture]
    public class AssertionResultTests
    {
        [Test]
        public void AssertionResult_Defaults_ToFailedOnInitialization()
        {
            var assertion = new Assertion("Test Assert", "Test Surface", null, null, true, false, false, false);

            AssertionResult sut = new AssertionResult(assertion, new Guid());

            Assert.IsTrue(sut.Failed);
        }

        [Test]
        public void AssertionResult_Stays_FailedOnFailureCompletion()
        {
            var assertion = new Assertion("Test Assert", "Test Surface", null, null, true, false, false, false);

            AssertionResult sut = new AssertionResult(assertion, new Guid());
            sut.Complete(false);

            Assert.IsTrue(sut.Failed);
        }

        [Test]
        public void AssertionResult_SwitchesTo_NonFailedOnSuccessfulCompletion()
        {
            var assertion = new Assertion("Test Assert", "Test Surface", null, null, true, false, false, false);

            AssertionResult sut = new AssertionResult(assertion, new Guid());
            sut.Complete(true);

            Assert.IsTrue(sut.Passed);
        }

        [Test]
        public void AssertionResult_Shows_FailedOnCompletionWithErrorRecord()
        {
            var assertion = new Assertion("Test Assert", "Test Surface", null, null, true, false, false, false);
            Exception ex = new Exception();
            var errorRecord = new ErrorRecord(ex, "Fake.Error.Id", ErrorCategory.InvalidOperation, null);

            AssertionResult sut = new AssertionResult(assertion, new Guid());
            sut.Complete(errorRecord);

            Assert.IsTrue(sut.Failed);
        }
    }
}