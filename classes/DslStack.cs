using System;
using System.Collections.Generic;

namespace Proviso.Models
{
    public class DslStack
    {
        private readonly List<string> _allowedMethods = new List<string>();
        private readonly List<string> _allowedFacetBlocks = new List<string>();
        private Stack<string> _methodsStack = new Stack<string>();
        private Stack<string> _facetsStack = new Stack<string>();

        private DslStack()
        {
            this._allowedMethods.Add("With");               // 0
            this._allowedMethods.Add("Secured-By");         // 1
            this._allowedMethods.Add("Validate");           // 2
            this._allowedMethods.Add("Configure");          // 2
            this._allowedMethods.Add("Process-Facet");      // 3 - CAN be called directly... not sure why anyone would want to... but permitted. 
            // TODO: add ... "Process" or "Bulk-Process" which would be a parent of FACETs... (and could only contain facets).

            this._allowedFacetBlocks.Add("Facet");              // 0
            this._allowedFacetBlocks.Add("Assertions");         // 1 - child of facet
            this._allowedFacetBlocks.Add("Assert");             // 2 - child of Assertions
            this._allowedFacetBlocks.Add("Rebase");             // 1 - child of facet
            this._allowedFacetBlocks.Add("Definitions");        // 1 - child of facet
            this._allowedFacetBlocks.Add("Definition");         // 2 - child of definitions
            this._allowedFacetBlocks.Add("Expect");             // 3 - child of definition
            this._allowedFacetBlocks.Add("Test");               // 3 - child of definition
            this._allowedFacetBlocks.Add("Configure");          // 3 - child of definition. 
            
        }

        public static DslStack Instance => new DslStack();

        public int FacetBlocksCount => this._facetsStack.Count;
        public int DslMethodsCount => this._methodsStack.Count;

        public string AddFacetBlock(string block)
        {
            if (!this._allowedFacetBlocks.Contains(block))
                return $"Invalid Proviso Facet Operation: [{block}] is not a valid Facet member.";

            // TODO: ... implement.


            return "";
        }

        public string AddDslMethod(string method)
        {
            if (!this._allowedMethods.Contains(method))
                return $"Invalid Proviso DSL: [{method}] is not a valid Proviso DSL method.";

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

            return "";
        }
    }
}
