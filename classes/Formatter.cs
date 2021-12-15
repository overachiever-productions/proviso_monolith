using System.Dynamic;

namespace Proviso
{
    public class Formatter
    {
        public static Formatter Instance => new Formatter();

        private Formatter(){}

        public string Abridge(string input, int maxLength)
        {
            string output = input.Trim();
            if (output.Length > maxLength)
                output = output.Substring(0, (maxLength - 1)) + '…';

            if (string.IsNullOrEmpty(output))
                output = "<EMPTY>";

            return output;
        }
    }
}
