import { Box } from '@welcome-ui/box'
import { Flex } from '@welcome-ui/flex'
import { Link } from '@welcome-ui/link'
import { Link as RouterLink, Outlet } from 'react-router-dom'

function Layout() {
  return (
    <Box backgroundColor="beige-20" h="100vh">
      <Box backgroundColor="black" p={20}>
        <Flex>
          <Link as={RouterLink} to="/" color="white">
            <div>Jobs</div>
          </Link>
        </Flex>
      </Box>
      <Box>
        <Outlet />
      </Box>
    </Box>
  )
}

export default Layout
