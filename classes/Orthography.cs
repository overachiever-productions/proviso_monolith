using System.Collections.Generic;
using System.Linq;

namespace Proviso
{
    public class Orthography
    {
        private readonly List<string> _allowedMethods = new List<string>();
        private readonly List<string> _allowedFacetBlocks = new List<string>();
        private readonly Stack<string> _methodsStack = new Stack<string>();
        private readonly Stack<string> _facetsStack = new Stack<string>();

        private Orthography()
        {
            this._allowedMethods.Add("With");                       // 0
            this._allowedMethods.Add("Secured-By");                 //  1
            this._allowedMethods.Add("Validate");                   //    2
            this._allowedMethods.Add("Configure");                  //    2
            this._allowedMethods.Add("Execute");                    //    2 - wrapper to allow processing of one or more facets... 
            this._allowedMethods.Add("Process-Facet");              //      3 - CAN be called directly... not sure why anyone would want to... but permitted. 
            

            this._allowedFacetBlocks.Add("Facet");                  // 0
            this._allowedFacetBlocks.Add("Assertions");             //  1 - child of facet
            this._allowedFacetBlocks.Add("Assert");                 //    2 - child of Assertions
            this._allowedFacetBlocks.Add("Rebase");                 //  1 - child of facet
            this._allowedFacetBlocks.Add("Definitions");            //  1 - child of facet
            this._allowedFacetBlocks.Add("Value-Definitions");      //  1 - child of facet
            this._allowedFacetBlocks.Add("Group-Definitions");      //  1 - child of facet
            this._allowedFacetBlocks.Add("Definition");             //    2 - child of definitions
            this._allowedFacetBlocks.Add("Expect");                 //      3 - child of definition
            this._allowedFacetBlocks.Add("Test");                   //      3 - child of definition
            this._allowedFacetBlocks.Add("Configure");              //      3 - child of definition. 
        }

        public static Orthography Instance => new Orthography();

        //public int FacetBlocksCount => this._facetsStack.Count;
        //public int DslMethodsCount => this._methodsStack.Count;

        public string AddFacetBlock(string block)
        {
            if (!this._allowedFacetBlocks.Contains(block))
                return "Invalid Proviso Facet Operation: [{block}] is not a valid Facet member.";

            // TODO: verify that usage of the syntax is correct.... 
            //      which'll actually be semi-difficult. 
            //          e.g, i COULD do something like .GetRankOfBlockName(block) ... which'd, return, say, 2 for Definition or Assert. 
            //              then, I could ask for .GetRankOfBlockName(this.FacetParent())... 
            //                  and, if the rank of the parent (for our current rank/value of 2) wasn't ... 1... then, throw an error. 
            //              only, that's SUPER naive. 
            //              e.g., assume that, instead of "Assert" or "Definition" the previously 'added' or 'defined' block was: 
            //                  3:Configure. 
            //              and, now, the next 'block-name' to be added is: Test (i.e., we've just jumped into another Definition's children). 
            //                  or, maybe the next 'block-name' is Definition (i.e., we left one defintion with 'Test' and we're now moving into
            //                      'Definition' -> 'Test' ... i'm still going to run into some ugly errors SOMEWHERE with this transition. 

            //      ultimately, i think i probably need: 
            //      this._tier1FacetStack... and this._tier2FacetStack, tier3, etc. 
            //              or something seriously ugly like that? 
            //              i.e., I don't think that a simple stack will do what I need it to do. 

            this._facetsStack.Push(block);

            return "";
        }

        public string AddDslMethod(string method)
        {
            if (!this._allowedMethods.Contains(method))
                return "Invalid Proviso DSL: [{method}] is not a valid Proviso DSL method.";

            // TODO: actually spend some time defining the rules for each element/method. 
            //      i.e., with HAS to be first. 
            //          but Configure|Validate|Process-Facet|Secured-By can all follow it. 
            //          However, Secured-By can't follow-anything but With
            //              and has to be before other commands, etc. 
            //          i.e., clearly delineate all rules before trying to implement logic.
            // TODO: this is crappy code - i.e., just pounded it out to test workflows/validation processes. 

            if (method == "With")
            {
                this._methodsStack.Clear();
                this._methodsStack.Push(method);
                return "";
            }

            if (method == "Validate")
            {
                if (this._methodsStack.Count < 1)
                {
                    return "Validate can't be called by itself. It needs to follow With... ";
                }
                this._methodsStack.Push(method);
            }

            this._methodsStack.Push(method);

            return "";
        }

        public string MethodParent()
        {
            return this._methodsStack.Skip(1).FirstOrDefault();
        }

        public string FacetParent()
        {
            return this._facetsStack.Skip(1).FirstOrDefault();
        }
    }
}
