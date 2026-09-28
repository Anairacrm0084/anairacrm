import ModulePage from '../ModulePage';
import {pages} from '../pageConfigs';
export default function Page(){ return <ModulePage config={{...pages['service-tickets'],dataSource:'service-tickets'}} /> }
