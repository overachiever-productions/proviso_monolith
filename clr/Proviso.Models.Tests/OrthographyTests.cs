using NUnit.Framework;

namespace Proviso.Models.Tests
{
    [TestFixture]
    public class OrthographyTests
    {
        // GRRR. Actually, Orthography.AddXXX methods do NOT throw. 
        //      they return strings (that are thrown from Posh - as that does a better job of preserviving the error details). 
        // Or... hmmm, I MIGHT want to test which approach does a better job of providing INSIGHTFUL error info: return string + throw from posh, or JUST throw from C#.

        //[Test]
        //public void AdditionOfInvalidMethod_Throws()
        //{
        //    Assert.Throws();
        //}

        //[Test]
        //public void AdditionOfValidMethod_DoesNotThrow()
        //{
        //    var sut = Orthography.Instance;
        //    sut.AddDslMethod("With");

        //}

        [Test]
        public void MethodParent_WithNoLoadedMethods_ReturnsNull()
        {
            var sut = Orthography.Instance;
            string parent = sut.MethodParent();

            Assert.That(string.IsNullOrEmpty(parent));
        }

        [Test]
        public void MethodParent_WithOnlyTheCurrentMethodLoaded_ReturnsNull()
        {
            var sut = Orthography.Instance;
            sut.AddDslMethod("With");

            string parent = sut.MethodParent();

            Assert.That(string.IsNullOrEmpty(parent));
        }

        [Test]
        public void MethodParent_WithValidParent_ReturnsParent()
        {
            var sut = Orthography.Instance;
            sut.AddDslMethod("With");
            sut.AddDslMethod("Secured-By");

            string parent = sut.MethodParent();

            StringAssert.AreEqualIgnoringCase("With", parent);
        }

        [Test]
        public void MethodParent_WithMultipleMethodsInStack_ReturnsCorrectParent()
        {
            var sut = Orthography.Instance;
            sut.AddDslMethod("With");
            sut.AddDslMethod("Secured-By");
            sut.AddDslMethod("Validate");
            sut.AddDslMethod("Execute");

            string parent = sut.MethodParent();

            StringAssert.AreEqualIgnoringCase("Validate", parent);
        }

        [Test]
        public void SurfaceParent_WithNoLoadedSurfaceMembers_ReturnsNull()
        {
            var sut = Orthography.Instance;
            string parent = sut.SurfaceParent();

            Assert.That(string.IsNullOrEmpty(parent));
        }

        [Test]
        public void SurfaceParent_WithOnlySurfaceRoot_ReturnsNull()
        {
            var sut = Orthography.Instance;
            sut.AddSurfaceBlock("Surface");
            
            string parent = sut.SurfaceParent();
            Assert.That(string.IsNullOrEmpty(parent));
        }

        [Test]
        public void SurfaceParent_WithValidParent_ReturnsParent()
        {
            var sut = Orthography.Instance;
            sut.AddSurfaceBlock("Surface");
            sut.AddSurfaceBlock("Assertions");

            string parent = sut.SurfaceParent();
            StringAssert.AreEqualIgnoringCase("Surface", parent);
        }

        [Test]
        public void SurfaceParent_WithMultipleParentNodes_ReturnsCorrectParent()
        {
            var sut = Orthography.Instance;
            sut.AddSurfaceBlock("Surface");
            sut.AddSurfaceBlock("Definitions");
            sut.AddSurfaceBlock("Definition");
            sut.AddSurfaceBlock("Expect");

            string parent = sut.SurfaceParent();
            StringAssert.AreEqualIgnoringCase("Definition", parent);
        }
    }
}
