import React from 'react';
import PropTypes from 'prop-types';
import RailsAuthenticityToken from '@cdo/apps/lib/util/RailsAuthenticityToken';
import HelpTip from '@cdo/apps/lib/ui/HelpTip';

export default function NewProgrammingExpressionForm({
  programmingEnvironmentsForSelect
}) {
  return (
    <form action="/programming_expressions" method="post">
      <RailsAuthenticityToken />
      <label>
        Programming Expression Slug
        <HelpTip>
          <p>
            The programming expression slug is used in URLs and cannot be
            updated once set. A slug can only contain lowercase letters, numbers
            and dashes.
          </p>
        </HelpTip>
        <input name="key" />
      </label>
      <label>
        Programming Environment
        <select name="programming_environment_id">
          {programmingEnvironmentsForSelect.map(programmingEnvironment => (
            <option
              key={programmingEnvironment.id}
              value={programmingEnvironment.id}
            >
              {programmingEnvironment.name}
            </option>
          ))}
        </select>
      </label>
      <br />
      <button className="btn btn-primary" type="submit">
        Save Changes
      </button>
    </form>
  );
}

NewProgrammingExpressionForm.propTypes = {
  programmingEnvironmentsForSelect: PropTypes.arrayOf(
    PropTypes.shape({id: PropTypes.number, name: PropTypes.string})
  ).isRequired
};
