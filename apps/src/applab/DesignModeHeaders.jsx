import PropTypes from 'prop-types';
import React from 'react';
import applabMsg from '@cdo/applab/locale';
import msg from '@cdo/locale';
import commonStyles from '../commonStyles';
import color from '../util/color';
import PaneHeader, {PaneButton, PaneSection} from '../templates/PaneHeader';
import SettingsCog from '../lib/ui/SettingsCog';
import ProjectTemplateWorkspaceIcon from '../templates/ProjectTemplateWorkspaceIcon';
import classNames from 'classnames';

export default class DesignModeHeaders extends React.Component {
  static propTypes = {
    handleVersionHistory: PropTypes.func.isRequired,
    onToggleToolbox: PropTypes.func.isRequired,
    isToolboxVisible: PropTypes.bool.isRequired,
    showProjectTemplateWorkspaceIcon: PropTypes.bool.isRequired,
    isRtl: PropTypes.bool.isRequired,
    isRunning: PropTypes.bool.isRequired,
    showMakerToggle: PropTypes.bool.isRequired,
    autogenerateML: PropTypes.func
  };

  onToggleToolbox = () => this.props.onToggleToolbox();

  chevronStyle(collapse) {
    const style = {
      display: 'inline-block',
      position: 'absolute',
      top: 0,
      left: 8,
      lineHeight: '30px',
      fontSize: 18,
      cursor: 'pointer',
      color: this.props.isRunning ? color.dark_charcoal : color.lighter_purple,
      ':hover': {
        color: color.white
      }
    };

    if (collapse) {
      style.transform = 'scale(-1, 1)';
    }

    return style;
  }

  hideToolboxIcon() {
    return (
      <i
        style={[commonStyles.hidden, this.chevronStyle(true)]}
        className="hide-toolbox-icon fa fa-chevron-circle-right"
        onClick={this.onToggleToolbox}
      />
    );
  }

  showToolboxIcon() {
    return (
      <i
        style={[commonStyles.hidden, this.chevronStyle(false)]}
        className="show-toolbox-icon fa fa-chevron-circle-right"
      />
    );
  }

  render() {
    const styles = {
      toolboxHeader: {
        display: this.props.isToolboxVisible ? 'flex' : 'none',
        justifyContent: 'space-between',
        width: 270,
        borderRight: '1px solid gray',
        float: 'left'
      },
      showToolboxHeader: {
        float: 'left',
        display: this.props.isToolboxVisible ? 'none' : 'flex',
        justifyContent: 'space-between',
        paddingLeft: 10
      },
      showToolboxClickable: {
        marginLeft: 18,
        ':hover': {
          color: color.white
        }
      },
      iconContainer: {
        float: 'right',
        marginRight: 10,
        marginLeft: 10,
        height: '100%'
      },
      assetsIcon: {
        fontSize: 18,
        verticalAlign: 'middle'
      },
      runningVersionHistoryButton: {
        color: color.dark_charcoal
      }
    };

    const hasFocus = !this.props.isRunning;

    const settingsCog = (
      <SettingsCog
        isRunning={this.props.isRunning}
        showMakerToggle={this.props.showMakerToggle}
        runModeIndicators
        autogenerateML={this.props.autogenerateML}
      />
    );

    return (
      <PaneHeader
        id="design-headers"
        dir={this.props.isRtl ? 'rtl' : 'ltr'}
        hasFocus={hasFocus}
        style={{color: 'white'}}
      >
        <PaneSection
          id="design-toolbox-header"
          className={classNames(
            'workspace-header',
            this.props.isRunning && 'is-running'
          )}
          style={styles.toolboxHeader}
        >
          <span>{this.hideToolboxIcon()}</span>
          <span>{applabMsg.designToolboxHeader()}</span>
          <span>{settingsCog}</span>
        </PaneSection>
        <PaneSection
          className={classNames(
            'workspace-header',
            this.props.isRunning && 'is-running'
          )}
          style={styles.showToolboxHeader}
        >
          <span
            key="show-toolbox-clickable"
            className="workspace-header-clickable"
            style={styles.showToolboxClickable}
            onClick={this.onToggleToolbox}
          >
            {this.showToolboxIcon()}
          </span>
          <span>{msg.showToolbox()}</span>
          <span>{settingsCog}</span>
        </PaneSection>
        <PaneButton
          id="design-mode-versions-header"
          style={this.props.isRunning ? styles.runningVersionHistoryButton : {}}
          iconClass="fa fa-clock-o"
          label={msg.showVersionsHeader()}
          headerHasFocus={hasFocus}
          isRtl={this.props.isRtl}
          onClick={this.props.handleVersionHistory}
        />
        <PaneSection
          id="design-workspace-header"
          className={classNames(
            'workspace-header',
            this.props.isRunning && 'is-running'
          )}
        >
          {this.props.showProjectTemplateWorkspaceIcon && (
            <ProjectTemplateWorkspaceIcon />
          )}
          <span>{applabMsg.designWorkspaceHeader()}</span>
        </PaneSection>
      </PaneHeader>
    );
  }
}
