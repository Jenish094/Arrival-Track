import React, { useState } from "react";
import Autosuggest from "react-autosuggest";
import { suggestAddresses } from "../api/geocode";

interface Props {
  label: string;
  value: string;
  onChange: (val: string) => void;
}

const AddressInput: React.FC<Props> = ({ label, value, onChange }) => {
  const [suggestions, setSuggestions] = useState<{ label: string; lat: number; lon: number }[]>([]);

  const onSuggestionsFetchRequested = async ({ value }: { value: string }) => {
    const results = await suggestAddresses(value);
    setSuggestions(results);
  };

  const onSuggestionsClearRequested = () => setSuggestions([]);

  const getSuggestionValue = (s: { label: string }) => s.label;
  const renderSuggestion = (s: { label: string }) => <div>{s.label}</div>;

  return (
    <div style={{ marginBottom: "1rem" }}>
      <label style={{ color: "white", fontWeight: "bold" }}>{label}</label>
      <Autosuggest
        suggestions={suggestions}
        onSuggestionsFetchRequested={onSuggestionsFetchRequested}
        onSuggestionsClearRequested={onSuggestionsClearRequested}
        getSuggestionValue={getSuggestionValue}
        renderSuggestion={renderSuggestion}
        inputProps={{
          value,
          onChange: (_: any, { newValue }: any) => onChange(newValue),
          placeholder: "Enter address",
          style: {
            width: "100%",
            padding: "0.5rem",
            borderRadius: "8px",
            border: "1px solid #555",
            marginTop: "0.3rem",
            background: "#222",
            color: "white",
          },
        }}
      />
    </div>
  );
};

export default AddressInput;
