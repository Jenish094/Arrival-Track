import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { useState } from "react";
import Autosuggest from "react-autosuggest";
import { suggestAddresses } from "../api/geocode";
const AddressInput = ({ label, value, onChange }) => {
    const [suggestions, setSuggestions] = useState([]);
    const onSuggestionsFetchRequested = async ({ value }) => {
        const results = await suggestAddresses(value);
        setSuggestions(results);
    };
    const onSuggestionsClearRequested = () => setSuggestions([]);
    const getSuggestionValue = (s) => s.label;
    const renderSuggestion = (s) => _jsx("div", { children: s.label });
    return (_jsxs("div", { style: { marginBottom: "1rem" }, children: [_jsx("label", { style: { color: "white", fontWeight: "bold" }, children: label }), _jsx(Autosuggest, { suggestions: suggestions, onSuggestionsFetchRequested: onSuggestionsFetchRequested, onSuggestionsClearRequested: onSuggestionsClearRequested, getSuggestionValue: getSuggestionValue, renderSuggestion: renderSuggestion, inputProps: {
                    value,
                    onChange: (_, { newValue }) => onChange(newValue),
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
                } })] }));
};
export default AddressInput;
