﻿using System.Collections.Generic;
using System.Linq;

namespace Proviso
{
    public class Orthography
    {
        private readonly List<string> _allowedMethods = new List<string>();
        private readonly List<string> _allowedSurfaceBlocks = new List<string>();
        private readonly Stack<string> _methodsStack = new Stack<string>();
        private readonly Stack<string> _surfacesStack = new Stack<string>();

        private Orthography()
        {
            this._allowedMethods.Add("Assign");                        // 0
            this._allowedMethods.Add("Map");                            //  1
            this._allowedMethods.Add("Target");                         //  1

            this._allowedMethods.Add("Evaluate");                   //   3
            this._allowedMethods.Add("Provision");                  //   3
            this._allowedMethods.Add("Execute-Runbook");            //     4

            this._allowedMethods.Add("Validate");                   //    2
            this._allowedMethods.Add("Configure");                  //    2
            this._allowedMethods.Add("Run");                        //    2
            this._allowedMethods.Add("Process-Surface");            //      3 - should NOT be called directly... 


            this._allowedSurfaceBlocks.Add("Runbook");                // 0

            this._allowedSurfaceBlocks.Add("Surface");                // 1
            this._allowedSurfaceBlocks.Add("Assertions");             //  2 - child of surface
            this._allowedSurfaceBlocks.Add("Assert");                 //    3 - child of Assertions
            this._allowedSurfaceBlocks.Add("Rebase");                 //  2 - child of surface
            this._allowedSurfaceBlocks.Add("Setup");                  //  2 - child of surface
            this._allowedSurfaceBlocks.Add("Aspect");                 //  2 - child of surface
            this._allowedSurfaceBlocks.Add("Build");                  //    3 - child of aspect
            this._allowedSurfaceBlocks.Add("Deploy");                 //    3 - child of aspect
            this._allowedSurfaceBlocks.Add("Facet");                  //    3 - child of aspect
            this._allowedSurfaceBlocks.Add("Expect");                 //      4 - child of facet
            this._allowedSurfaceBlocks.Add("Test");                   //      4 - child of facet
            this._allowedSurfaceBlocks.Add("Configure");              //      4 - child of facet 
        }

        public static Orthography Instance => new Orthography();

        //public int SurfaceBlocksCount => this._surfacesStack.Count;
        //public int DslMethodsCount => this._methodsStack.Count;

        public string AddSurfaceBlock(string block)
        {
            if (!this._allowedSurfaceBlocks.Contains(block))
                return $"Invalid Proviso Surface Operation: [{block}] is not a valid Surface member.";

            // TODO: verify that usage of the syntax is correct.... 
            //      which'll actually be semi-difficult. 
            //          e.g, i COULD do something like .GetRankOfBlockName(block) ... which'd, return, say, 2 for Facet or Assert. 
            //              then, I could ask for .GetRankOfBlockName(this.SurfaceParent())... 
            //                  and, if the rank of the parent (for our current rank/value of 2) wasn't ... 1... then, throw an error. 
            //              only, that's SUPER naive. 
            //              e.g., assume that, instead of "Assert" or "Facet" the previously 'added' or 'defined' block was: 
            //                  3:Configure. 
            //              and, now, the next 'block-name' to be added is: Test (i.e., we've just jumped into another Facet's children). 
            //                  or, maybe the next 'block-name' is Facet (i.e., we left one facet with 'Test' and we're now moving into
            //                      'Facet' -> 'Test' ... i'm still going to run into some ugly errors SOMEWHERE with this transition. 

            //      ultimately, i think i probably need: 
            //      this._tier1FacetStack... and this._tier2FacetStack, tier3, etc. 
            //              or something seriously ugly like that? 
            //              i.e., I don't think that a simple stack will do what I need it to do. 

            this._surfacesStack.Push(block);

            return "";
        }

        public string AddDslMethod(string method)
        {
            if (!this._allowedMethods.Contains(method))
                return $"Invalid Proviso DSL: [{method}] is not a valid Proviso DSL method.";

            // TODO: actually spend some time defining the rules for each element/method. 
            //      i.e., with HAS to be first. 
            //          but Configure|Validate|Process-Surface|Secured-By can all follow it. 
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
                    return "Validate can't be executed until a Target has been specified... ";
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

        public string SurfaceParent()
        {
            return this._surfacesStack.Skip(1).FirstOrDefault();
        }
    }
}
