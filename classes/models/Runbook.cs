using System.Collections.Generic;

namespace Proviso.Models
{
    public class Runbook
    {
        public string  Name { get; set; }
        public string FileName { get; set; }
        public string SourcePath { get; set; }

        public List<Facet> Surfaces { get; set; }


    }
}