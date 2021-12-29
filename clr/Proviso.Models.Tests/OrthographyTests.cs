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
        public void FacetParent_WithNoLoadedFacetsMembers_ReturnsNull()
        {
            var sut = Orthography.Instance;
            string parent = sut.FacetParent();

            Assert.That(string.IsNullOrEmpty(parent));
        }

        [Test]
        public void FacetParent_WithOnlyFacetRoot_ReturnsNull()
        {
            var sut = Orthography.Instance;
            sut.AddFacetBlock("Facet");
            
            string parent = sut.FacetParent();
            Assert.That(string.IsNullOrEmpty(parent));
        }

        [Test]
        public void FacetParent_WithValidParent_ReturnsParent()
        {
            var sut = Orthography.Instance;
            sut.AddFacetBlock("Facet");
            sut.AddFacetBlock("Assertions");

            string parent = sut.FacetParent();
            StringAssert.AreEqualIgnoringCase("Facet", parent);
        }

        [Test]
        public void FacetParent_WithMultipleParentNodes_ReturnsCorrectParent()
        {
            var sut = Orthography.Instance;
            sut.AddFacetBlock("Facet");
            sut.AddFacetBlock("Definitions");
            sut.AddFacetBlock("Definition");
            sut.AddFacetBlock("Expect");

            string parent = sut.FacetParent();
            StringAssert.AreEqualIgnoringCase("Definition", parent);
        }
    }
}
