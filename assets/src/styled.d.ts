import 'styled-components'
import '@xstyled/styled-components'
import { WuiTheme } from '@welcome-ui/core'

declare module '@xstyled/system' {
  export type Theme = WuiTheme
}

declare module 'styled-components' {
  export type DefaultTheme = WuiTheme
}
