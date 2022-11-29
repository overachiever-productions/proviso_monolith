using Proviso.Enums;

namespace Proviso.Processing
{
    public class ConfigEntry
    {
        public string[] KeyParts { get; private set; }  // this isn't really immutable... 
        public string ConfigRoot { get; private set; }  // also... not really immutable... 

        public string OriginalKey { get; set; }
        public string NormalizedKey { get; set; }
        public string TokenizedKey { get; set; }

        public bool IsValid { get; set; }
        public string InvalidReason { get; set; }

        public SqlInstanceKeyType SqlInstanceKeyType { get; set; }
        public string SqlInstanceName { get; set; }
        public string ObjectInstanceName { get; set; }

        public ConfigEntryDataType DefaultDataType { get; set; }
        public ConfigEntryDataType DataType { get; set; }

        public object Value { get; set; }
        public object DefaultValue { get; set; }

        private ConfigEntry(string key)
        {
            this.OriginalKey = key;
            this.KeyParts = key.Split('.');

            // todo, throw if parts[0] is null or there aren't any parts... 
            this.ConfigRoot = this.KeyParts[0];

            this.SqlInstanceKeyType = SqlInstanceKeyType.UnChecked;

            this.IsValid = false;
        }

        public static ConfigEntry ConfigEntryFromKey(string key)
        {
            var parts = key.Split('.');
            return new ConfigEntry(key);
        }
    }
}
